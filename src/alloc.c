/* Allocator and garbage collector.

Copyright (C) 1985-1986, 1988, 1993-1995, 1997-2022 Free Software
Foundation, Inc.

This file is NOT part of GNU Emacs.

GNU Emacs is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

GNU Emacs is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.  */

/* The core gc task is marking Lisp objects in so-called vectorlikes, an
   unfortunate umbrella term for Emacs's various structs (buffers,
   windows, frames, etc.). "Vectorlikes" is meant to capture their
   function as containers of heterogenous Lisp objects.

   Not content with just one confusing moniker, Emacs also refers to
   vectorlikes as "pseudovectors", emphasizing their containing
   non-Lisp member data (which an "authentic" Lisp_Vector could not).

   Except for special cases (`struct buffer`), vectorlikes are relied upon
   to consist of a header, Lisp_Object fields, then non-Lisp fields,
   in that precise order.  Pervasive in the GC code is casting [1]
   the vectorlike as a `struct Lisp_Vector *`, then iterating
   over its N Lisp objects, say to mark them from reclamation,
   where N is masked off from the header (PSEUDOVECTOR_SIZE_MASK).
*/

#include "alloc.h"

/* MALLOC_SIZE_NEAR (N) is a good number to pass to malloc when
   allocating a block of memory with size close to N bytes.
   For best results N should be a power of 2.

   When calculating how much memory to allocate, GNU malloc (SIZE)
   adds sizeof (size_t) to SIZE for internal overhead, and then rounds
   up to a multiple of MALLOC_ALIGNMENT.  Emacs can improve
   performance a bit on GNU platforms by arranging for the resulting
   size to be a power of two.  This heuristic is good for glibc 2.26
   (2017) and later, and does not affect correctness on other
   platforms.  */

#define MALLOC_SIZE_NEAR(n) \
  (ROUNDUP (max (n, sizeof (size_t)), MALLOC_ALIGNMENT) - sizeof (size_t))
#ifdef __i386
enum { MALLOC_ALIGNMENT = 16 };
#else
enum { MALLOC_ALIGNMENT = max (2 * sizeof (size_t), alignof (long double)) };
#endif

/* Mark, unmark, query mark bit of a Lisp string.  S must be a pointer
   to a struct Lisp_String.  */

#define XMARK_STRING(S)		((S)->u.s.size |= ARRAY_MARK_FLAG)
#define XUNMARK_STRING(S)	((S)->u.s.size &= ~ARRAY_MARK_FLAG)
#define XSTRING_MARKED_P(S)	(((S)->u.s.size & ARRAY_MARK_FLAG) != 0)

#define XMARK_VECTOR(V)		((V)->header.size |= ARRAY_MARK_FLAG)
#define XUNMARK_VECTOR(V)	((V)->header.size &= ~ARRAY_MARK_FLAG)
#define XVECTOR_MARKED_P(V)	(((V)->header.size & ARRAY_MARK_FLAG) != 0)

/* Arbitrarily set in 2012 in commit 0dd6d66.  */
#define GC_DEFAULT_THRESHOLD ((1 << 17) * word_size)

static bool gc_inhibited;

#ifdef HAVE_PDUMPER
/* Number of finalizers run: used to loop over GC until we stop
   generating garbage.  */
int number_finalizers_run;
#endif

/* Exposed to lisp.h so that maybe_garbage_collect() can inline.  */

EMACS_INT bytes_since_gc;
EMACS_INT bytes_between_gc;
Lisp_Object Vmemory_full;
bool gc_in_progress;

/* Last recorded live and free-list counts.  */
static struct
{
  size_t total_conses, total_free_conses;
  size_t total_symbols, total_free_symbols;
  size_t total_strings, total_free_strings;
  size_t total_string_bytes;
  size_t total_vectors, total_vector_slots, total_free_vector_slots;
  size_t total_floats, total_free_floats;
  size_t total_intervals, total_free_intervals;
  size_t total_buffers;
} gcstat;

enum mem_type
{
  MEM_TYPE_NON_LISP,
  MEM_TYPE_CONS,
  MEM_TYPE_STRING,
  MEM_TYPE_SYMBOL,
  MEM_TYPE_FLOAT,
  /* Includes vectors but not non-bool vectorlikes. */
  MEM_TYPE_VECTORLIKE,
  /* Non-bool vectorlikes.  */
  MEM_TYPE_VBLOCK,
};

/* Conservative stack scanning (the requirement that gc knows when a C
   pointer points to Lisp data) relies on lisp_malloc() registering
   allocations to a red-black tree.

   A red-black tree is a binary tree "fixed" after every insertion or
   deletion such that:

   1. Every node is either red or black.
   2. Every leaf is black.
   3. If a node is red, then both its children are black.
   4. Every simple path from a node to a descendant leaf contains
      the same number of black nodes.
   5. The root is always black.

   These invariants balance the tree so that its height can be no
   greater than 2 log(N+1), where N is the number of internal nodes.
   Searches, insertions and deletions are done in O(log N).  */

struct mem_node
{
  /* Children of this node.  These pointers are never NULL.  When there
     is no child, the value is CMEM_NIL, which points to a dummy node.  */
  struct mem_node *left, *right;

  /* The parent of this node.  In the root node, this is NULL.  */
  struct mem_node *parent;

  /* Start and end of allocated region.  */
  void *start, *end;

  /* Node color.  */
  enum {MEM_BLACK, MEM_RED} color;

  /* Memory type.  */
  enum mem_type type;
};

struct mem_node mem_z;
#define MEM_NIL &mem_z

/* True if malloc (N) is known to return storage suitably aligned for
   Lisp objects whenever N is a multiple of LISP_ALIGNMENT, or,
   equivalently when alignof (max_align_t) is a multiple of
   LISP_ALIGNMENT.  This works even for buggy platforms like MinGW
   circa 2020, where alignof (max_align_t) is 16 even though the
   malloc alignment is only 8, and where Emacs still works because it
   never does anything that requires an alignment of 16.  */
enum { MALLOC_IS_LISP_ALIGNED = alignof (max_align_t) % LISP_ALIGNMENT == 0 };

#define MALLOC_PROBE(size)			\
  do {						\
    if (profiler_memory_running)		\
      malloc_probe (size);			\
  } while (0)

/* Initialize it to a nonzero value to force it into data space
   (rather than bss space).  That way unexec will remap it into text
   space (pure), on some systems.  We have not implemented the
   remapping on more recent systems because this is less important
   nowadays than in the days of small memories and timesharing.  */

EMACS_INT pure[(PURESIZE + sizeof (EMACS_INT) - 1) / sizeof (EMACS_INT)] = {1,};
#define PUREBEG (char *) pure

/* Pointer to the pure area, and its size.  */

static char *purebeg;
static ptrdiff_t pure_size;

/* Number of bytes of pure storage used before pure storage overflowed.
   If this is non-zero, this implies that an overflow occurred.  */

static ptrdiff_t pure_bytes_used_before_overflow;

/* Index in pure at which next pure Lisp object will be allocated..  */

static ptrdiff_t pure_bytes_used_lisp;

/* Number of bytes allocated for non-Lisp objects in pure storage.  */

static ptrdiff_t pure_bytes_used_non_lisp;

/* If nonzero, this is a warning delivered by malloc and not yet
   displayed.  */

const char *pending_malloc_warning;

/* Pointer sanity only on request.  FIXME: Code depending on
   SUSPICIOUS_OBJECT_CHECKING is obsolete; remove it entirely.  */
#ifdef ENABLE_CHECKING
#define SUSPICIOUS_OBJECT_CHECKING 1
#endif

#ifdef SUSPICIOUS_OBJECT_CHECKING
struct suspicious_free_record
{
  void *suspicious_object;
  void *backtrace[128];
};
static void *suspicious_objects[32];
static int suspicious_object_index;
struct suspicious_free_record suspicious_free_history[64] EXTERNALLY_VISIBLE;
static int suspicious_free_history_index;
/* Find the first currently-monitored suspicious pointer in range
   [begin,end) or NULL if no such pointer exists.  */
static void *find_suspicious_object_in_range (void *begin, void *end);
static void detect_suspicious_free (void *ptr);
#else
# define find_suspicious_object_in_range(begin, end) ((void *) NULL)
# define detect_suspicious_free(ptr) ((void) 0)
#endif

static void unchain_finalizer (struct Lisp_Finalizer *);
static void mark_terminals (void);
static void gc_sweep (void);
static Lisp_Object make_pure_vector (ptrdiff_t);
static void mark_buffer (struct buffer *);

static void compact_small_strings (void);
static void free_large_strings (void);
extern Lisp_Object which_symbols (Lisp_Object, EMACS_INT) EXTERNALLY_VISIBLE;

static bool vectorlike_marked_p (union vectorlike_header const *);
static void set_vectorlike_marked (union vectorlike_header *);
static bool vector_marked_p (struct Lisp_Vector const *);
static void set_vector_marked (struct Lisp_Vector *v);
static bool interval_marked_p (INTERVAL);
static void set_interval_marked (INTERVAL);

static bool
deadp (Lisp_Object x)
{
  return EQ (x, dead_object ());
}

#ifdef GC_MALLOC_CHECK

enum mem_type allocated_mem_type;

#endif /* GC_MALLOC_CHECK */

/* Root of the tree describing allocated Lisp memory.  */

static struct mem_node *mem_root;

/* Lowest and highest known address in the heap.  */

static void *min_heap_address, *max_heap_address;

/* Sentinel node of the tree.  */

static struct mem_node *mem_insert (void *, void *, enum mem_type);
static void mem_insert_fixup (struct mem_node *);
static void mem_rotate_left (struct mem_node *);
static void mem_rotate_right (struct mem_node *);
static void mem_delete (struct mem_node *);
static void mem_delete_fixup (struct mem_node *);

/* Addresses of staticpro'd variables.  Initialize it to a nonzero
   value if we might unexec; otherwise some compilers put it into
   BSS.  */

Lisp_Object const *staticvec[NSTATICS];

/* Index of next unused slot in staticvec.  */

int staticidx;

static void *pure_alloc (size_t, int);

/* Return PTR rounded up to the next multiple of ALIGNMENT.  */

static void *
pointer_align (void *ptr, int alignment)
{
  return (void *) ROUNDUP ((uintptr_t) ptr, alignment);
}

/* Extract the pointer hidden within O.  */

static ATTRIBUTE_NO_SANITIZE_UNDEFINED void *
XPNTR (Lisp_Object a)
{
  return (SYMBOLP (a)
	  ? (char *) lispsym + (XLI (a) - LISP_WORD_TAG (Lisp_Symbol))
	  : (char *) XLP (a) - (XLI (a) & ~VALMASK));
}

static void
XFLOAT_INIT (Lisp_Object f, double n)
{
  XFLOAT (f)->u.data = n;
}

/* Head of a circularly-linked list of extant finalizers. */
struct Lisp_Finalizer finalizers;

/* Head of a circularly-linked list of finalizers that must be invoked
   because we deemed them unreachable.  This list must be global, and
   not a local inside garbage_collect, in case we GC again while
   running finalizers.  */
struct Lisp_Finalizer doomed_finalizers;


#if defined SIGDANGER || (!defined SYSTEM_MALLOC && !defined HYBRID_MALLOC)

/* Function malloc calls this if it finds we are near exhausting storage.  */

void
malloc_warning (const char *str)
{
  pending_malloc_warning = str;
}

#endif

/* Display an already-pending malloc warning.  */

void
display_malloc_warning (void)
{
  call3 (intern ("display-warning"),
	 intern ("alloc"),
	 build_string (pending_malloc_warning),
	 intern (":emergency"));
  pending_malloc_warning = 0;
}

/* True if a malloc-returned pointer P is suitably aligned for SIZE,
   where Lisp object alignment may be needed if SIZE is a multiple of
   LISP_ALIGNMENT.  */

static bool
laligned (void *p, size_t size)
{
  return (MALLOC_IS_LISP_ALIGNED
	  || (intptr_t) p % LISP_ALIGNMENT == 0
	  || size % LISP_ALIGNMENT != 0);
}

/* Like malloc but check for no memory and block interrupt input.  */

void *
xmalloc (size_t size)
{
  void *val = lmalloc (size, false);
  if (! val)
    memory_full (size);
  MALLOC_PROBE (size);
  return val;
}

/* Like the above, but zeroes out the memory just allocated.  */

void *
xzalloc (size_t size)
{
  void *val = lmalloc (size, true);
  if (! val)
    memory_full (size);
  MALLOC_PROBE (size);
  return val;
}

/* Like realloc but check for no memory and block interrupt input.  */

void *
xrealloc (void *block, size_t size)
{
  /* We can but won't assume realloc (NULL, size) works.  */
  void *val = block ? lrealloc (block, size) : lmalloc (size, false);
  if (! val)
    memory_full (size);
  MALLOC_PROBE (size);
  return val;
}

/* Like free() but check pdumper_object_p().  */

void
xfree (void *block)
{
  if (block && ! pdumper_object_p (block))
    free (block);
}

/* Other parts of Emacs pass large int values to allocator functions
   expecting ptrdiff_t.  This is portable in practice, but check it to
   be safe.  */
verify (INT_MAX <= PTRDIFF_MAX);

/* Allocate an array of NITEMS items, each of size ITEM_SIZE.
   Signal an error on memory exhaustion, and block interrupt input.  */

void *
xnmalloc (ptrdiff_t nitems, ptrdiff_t item_size)
{
  eassert (0 <= nitems && 0 < item_size);
  ptrdiff_t nbytes;
  if (INT_MULTIPLY_WRAPV (nitems, item_size, &nbytes) || SIZE_MAX < nbytes)
    memory_full (SIZE_MAX);
  return xmalloc (nbytes);
}

/* Reallocate an array PA to make it of NITEMS items, each of size ITEM_SIZE.
   Signal an error on memory exhaustion, and block interrupt input.  */

void *
xnrealloc (void *pa, ptrdiff_t nitems, ptrdiff_t item_size)
{
  eassert (0 <= nitems && 0 < item_size);
  ptrdiff_t nbytes;
  if (INT_MULTIPLY_WRAPV (nitems, item_size, &nbytes) || SIZE_MAX < nbytes)
    memory_full (SIZE_MAX);
  return xrealloc (pa, nbytes);
}

/* Grow PA, which points to an array of *NITEMS items, and return the
   location of the reallocated array, updating *NITEMS to reflect its
   new size.  The new array will contain at least NITEMS_INCR_MIN more
   items, but will not contain more than NITEMS_MAX items total.
   ITEM_SIZE is the size of each item, in bytes.

   ITEM_SIZE and NITEMS_INCR_MIN must be positive.  *NITEMS must be
   nonnegative.  If NITEMS_MAX is -1, it is treated as if it were
   infinity.

   If PA is null, then allocate a new array instead of reallocating
   the old one.

   Block interrupt input as needed.  If memory exhaustion occurs, set
   *NITEMS to zero if PA is null, and signal an error (i.e., do not
   return).

   Thus, to grow an array A without saving its old contents, do
   { xfree (A); A = NULL; A = xpalloc (NULL, &AITEMS, ...); }.
   The A = NULL avoids a dangling pointer if xpalloc exhausts memory
   and signals an error, and later this code is reexecuted and
   attempts to free A.  */

void *
xpalloc (void *pa, ptrdiff_t *nitems, ptrdiff_t nitems_incr_min,
	 ptrdiff_t nitems_max, ptrdiff_t item_size)
{
  ptrdiff_t n0 = *nitems;
  eassume (0 < item_size && 0 < nitems_incr_min && 0 <= n0 && -1 <= nitems_max);

  /* The approximate size to use for initial small allocation
     requests.  This is the largest "small" request for the GNU C
     library malloc.  */
  enum { DEFAULT_MXFAST = 64 * sizeof (size_t) / 4 };

  /* If the array is tiny, grow it to about (but no greater than)
     DEFAULT_MXFAST bytes.  Otherwise, grow it by about 50%.
     Adjust the growth according to three constraints: NITEMS_INCR_MIN,
     NITEMS_MAX, and what the C language can represent safely.  */

  ptrdiff_t n, nbytes;
  if (INT_ADD_WRAPV (n0, n0 >> 1, &n))
    n = PTRDIFF_MAX;
  if (0 <= nitems_max && nitems_max < n)
    n = nitems_max;

  ptrdiff_t adjusted_nbytes
    = ((INT_MULTIPLY_WRAPV (n, item_size, &nbytes) || SIZE_MAX < nbytes)
       ? min (PTRDIFF_MAX, SIZE_MAX)
       : nbytes < DEFAULT_MXFAST ? DEFAULT_MXFAST : 0);
  if (adjusted_nbytes)
    {
      n = adjusted_nbytes / item_size;
      nbytes = adjusted_nbytes - adjusted_nbytes % item_size;
    }

  if (! pa)
    *nitems = 0;
  if (n - n0 < nitems_incr_min
      && (INT_ADD_WRAPV (n0, nitems_incr_min, &n)
	  || (0 <= nitems_max && nitems_max < n)
	  || INT_MULTIPLY_WRAPV (n, item_size, &nbytes)))
    memory_full (SIZE_MAX);
  pa = xrealloc (pa, nbytes);
  *nitems = n;
  return pa;
}

/* Like strdup(), but uses xmalloc().  */

char *
xstrdup (const char *s)
{
  ptrdiff_t size;
  eassert (s);
  size = strlen (s) + 1;
  return memcpy (xmalloc (size), s, size);
}

/* Like above, but duplicates Lisp string to C string.  */

char *
xlispstrdup (Lisp_Object string)
{
  ptrdiff_t size = SBYTES (string) + 1;
  return memcpy (xmalloc (size), SSDATA (string), size);
}

/* Assign to *PTR a copy of STRING, freeing any storage *PTR formerly
   pointed to.  If STRING is null, assign it without copying anything.
   Allocate before freeing, to avoid a dangling pointer if allocation
   fails.  */

void
dupstring (char **ptr, char const *string)
{
  char *old = *ptr;
  *ptr = string ? xstrdup (string) : 0;
  xfree (old);
}

/* Like putenv, but (1) use the equivalent of xmalloc and (2) the
   argument is a const pointer.  */

void
xputenv (char const *string)
{
  if (putenv ((char *) string) != 0)
    memory_full (0);
}

/* Return a newly allocated memory block of SIZE bytes, remembering
   to free it when unwinding.  */
void *
record_xmalloc (size_t size)
{
  void *p = xmalloc (size);
  record_unwind_protect_ptr (xfree, p);
  return p;
}

/* Like malloc but used for allocating Lisp data.  NBYTES is the
   number of bytes to allocate, TYPE describes the intended use of the
   allocated memory block (for strings, for conses, ...).  */

#if ! USE_LSB_TAG
void *lisp_malloc_loser EXTERNALLY_VISIBLE;
#endif

static void *
lisp_malloc (size_t nbytes, bool q_clear, enum mem_type type)
{
  register void *val;

#ifdef GC_MALLOC_CHECK
  allocated_mem_type = type;
#endif

  val = lmalloc (nbytes, q_clear);

#if ! USE_LSB_TAG
  /* If the memory just allocated cannot be addressed thru a Lisp
     object's pointer, and it needs to be,
     that's equivalent to running out of memory.  */
  if (val && type != MEM_TYPE_NON_LISP)
    {
      Lisp_Object tem;
      XSETCONS (tem, (char *) val + nbytes - 1);
      if ((char *) XCONS (tem) != (char *) val + nbytes - 1)
	{
	  lisp_malloc_loser = val;
	  free (val);
	  val = 0;
	}
    }
#endif

#ifndef GC_MALLOC_CHECK
  if (val && type != MEM_TYPE_NON_LISP)
    mem_insert (val, (char *) val + nbytes, type);
#endif

  if (! val)
    memory_full (nbytes);
  MALLOC_PROBE (nbytes);
  return val;
}

/* Free BLOCK.  This must be called to free memory allocated with a
   call to lisp_malloc.  */

static void
lisp_free (void *block)
{
  if (block && ! pdumper_object_p (block))
    {
      free (block);
#ifndef GC_MALLOC_CHECK
      mem_delete (mem_find (block));
#endif
    }
}

/* The allocator malloc's blocks of BLOCK_ALIGN bytes.

   Structs for blocks are statically defined, so calculate (at compile-time)
   how many of each type will fit into its respective block.

   For simpler blocks consisting only of an object array and a next pointer,
   the numerator need only subtract off the size of the next pointer.

   For blocks with an additional gcmarkbits array, say float_block, we
   solve for y in the inequality:

     BLOCK_ALIGN > y * sizeof (Lisp_Float) + sizeof (bits_word) * (y /
     BITS_PER_BITS_WORD + 1) + sizeof (struct float_block *)
*/

enum
{
  BLOCK_NBITS = 10,
  BLOCK_ALIGN = (1 << BLOCK_NBITS),
  BLOCK_NBYTES = BLOCK_ALIGN - sizeof (uintptr_t), // subtract next ptr
  BLOCK_NINTERVALS = (BLOCK_NBYTES) / sizeof (struct interval),
  BLOCK_NSTRINGS = (BLOCK_NBYTES) / sizeof (struct Lisp_String),
  BLOCK_NSYMBOLS = (BLOCK_NBYTES) / sizeof (struct Lisp_Symbol),
  BLOCK_NFLOATS = ((BITS_PER_BITS_WORD / sizeof (bits_word))
		   * (BLOCK_NBYTES - sizeof (bits_word))
		   / ((BITS_PER_BITS_WORD / sizeof (bits_word))
		      * sizeof (struct Lisp_Float)
		      + 1)),
  BLOCK_NCONS = ((BITS_PER_BITS_WORD / sizeof (bits_word))
		 * (BLOCK_NBYTES - sizeof (bits_word))
		 / ((BITS_PER_BITS_WORD / sizeof (bits_word))
		    * sizeof (struct Lisp_Cons)
		    + 1)),

  /* Size `struct vector_block` */
  VBLOCK_ALIGN = (1 << PSEUDOVECTOR_SIZE_BITS),
  VBLOCK_NBYTES = VBLOCK_ALIGN - sizeof (uintptr_t), // subtract next ptr
  LISP_VECTOR_MIN = header_size + sizeof (Lisp_Object), // vector of one
  LARGE_VECTOR_THRESH = (VBLOCK_NBYTES >> 1) - word_size,

  /* Amazingly, free list per vector word-length.  */
  VBLOCK_NFREE_LISTS = 1 + (VBLOCK_NBYTES - LISP_VECTOR_MIN) / word_size,
};
// should someone decide to muck with VBLOCK_ALIGN...
verify (VBLOCK_ALIGN % LISP_ALIGNMENT == 0);
verify (VBLOCK_ALIGN <= (1 << PSEUDOVECTOR_SIZE_BITS));

#if (defined HAVE_ALIGNED_ALLOC			\
     || (defined HYBRID_MALLOC			\
	 ? defined HAVE_POSIX_MEMALIGN		\
	 : !defined SYSTEM_MALLOC))
# define USE_ALIGNED_ALLOC 1
#elif !defined HYBRID_MALLOC && defined HAVE_POSIX_MEMALIGN
# define USE_ALIGNED_ALLOC 1
# define aligned_alloc my_aligned_alloc /* Avoid collision with lisp.h.  */
static void *
aligned_alloc (size_t alignment, size_t size)
{
  /* Permit suspect assumption that ALIGNMENT is either BLOCK_ALIGN or
     LISP_ALIGNMENT since we'll rarely get here.  */
  eassume (alignment == BLOCK_ALIGN
	   || (! MALLOC_IS_LISP_ALIGNED && alignment == LISP_ALIGNMENT));

  /* Verify POSIX invariant ALIGNMENT = (2^x) * sizeof (void *).  */
  verify (BLOCK_ALIGN % sizeof (void *) == 0
	  && POWER_OF_2 (BLOCK_ALIGN / sizeof (void *)));
  verify (MALLOC_IS_LISP_ALIGNED
	  || (LISP_ALIGNMENT % sizeof (void *) == 0
	      && POWER_OF_2 (LISP_ALIGNMENT / sizeof (void *))));

  void *p;
  return posix_memalign (&p, alignment, size) == 0 ? p : 0;
}
#endif

/* Request at least SIZE bytes from malloc, ensuring returned
   pointer is Lisp-aligned.

   If T is an enum Lisp_Type and L = make_lisp_ptr (P, T), then
   code seeking P such that XPNTR (L) == P and XTYPE (L) == T, or,
   in less formal terms, seeking to allocate a Lisp object, should
   call lmalloc().

   Q_CLEAR uses calloc() instead of malloc().
   */

void *
lmalloc (size_t size, bool q_clear)
{
  /* xrealloc() relies on lmalloc() returning non-NULL even for SIZE
     == 0.  So, if ! MALLOC_0_IS_NONNULL, must avoid malloc'ing 0.  */
  size_t adjsize = MALLOC_0_IS_NONNULL ? size : max (size, LISP_ALIGNMENT);

  /* Prefer malloc() but if ! MALLOC_IS_LISP_ALIGNED, an exceptional
     case, then prefer aligned_alloc(), provided SIZE is a multiple of
     ALIGNMENT which aligned_alloc() requires.  */
#ifdef USE_ALIGNED_ALLOC
  if (! MALLOC_IS_LISP_ALIGNED)
    {
      if (adjsize % LISP_ALIGNMENT == 0)
	{
	  void *p = aligned_alloc (LISP_ALIGNMENT, adjsize);
	  if (q_clear && p && adjsize)
	    memclear (p, adjsize);
	  return p;
	}
      else
	{
	  /* Otherwise resign ourselves to loop that may never
	     terminate.  */
	}
    }
#endif
  void *p = NULL;
  for (;;)
    {
      p = q_clear ? calloc (1, adjsize) : malloc (adjsize);
      if (! p || MALLOC_IS_LISP_ALIGNED || laligned (p, adjsize))
	break;
      free (p);
      adjsize = max (adjsize, adjsize + LISP_ALIGNMENT);
    }
  eassert (! p || laligned (p, adjsize));
  return p;
}

void *
lrealloc (void *p, size_t size)
{
  /* xrealloc() relies on lrealloc() returning non-NULL even for size
     == 0.  MALLOC_0_IS_NONNULL does not mean REALLOC_0_IS_NONNULL.  */
  size_t adjsize = max (size, LISP_ALIGNMENT);
  void *newp = p;
  for (;;)
    {
      newp = realloc (newp, adjsize);
      if (! adjsize || ! newp || MALLOC_IS_LISP_ALIGNED || laligned (newp, adjsize))
	break;
      adjsize = max (adjsize, adjsize + LISP_ALIGNMENT);
    }
  eassert (! newp || laligned (newp, adjsize));
  return newp;
}

/* An aligned block of memory.  */
struct ablock
{
  union
  {
    char payload[BLOCK_NBYTES];
    struct ablock *next_free;
  } x;

  /* ABASE is the aligned base of the ablocks.  It is overloaded to
     hold a virtual "busy" field that counts twice the number of used
     ablock values in the parent ablocks, plus one if the real base of
     the parent ablocks is ABASE (if the "busy" field is even, the
     word before the first ablock holds a pointer to the real base).
     The first ablock has a "busy" ABASE, and the others have an
     ordinary pointer ABASE.  To tell the difference, the code assumes
     that pointers, when cast to uintptr_t, are at least 2 *
     ABLOCKS_NBLOCKS + 1.  */
  struct ablocks *abase;
};
verify (sizeof (struct ablock) % BLOCK_ALIGN == 0);

#define ABLOCKS_NBLOCKS (1 << 4)

struct ablocks
{
  struct ablock blocks[ABLOCKS_NBLOCKS];
};
verify (sizeof (struct ablocks) % BLOCK_ALIGN == 0);

#define ABLOCK_ABASE(block) \
  (((uintptr_t) (block)->abase) <= (1 + 2 * ABLOCKS_NBLOCKS)	\
   ? (struct ablocks *) (block)					\
   : (block)->abase)

/* Virtual "busy" field.  */
#define ABLOCKS_BUSY(a_base) ((a_base)->blocks[0].abase)

/* Pointer to the (not necessarily aligned) malloc block.  */
#ifdef USE_ALIGNED_ALLOC
#define ABLOCKS_BASE(abase) (abase)
#else
#define ABLOCKS_BASE(abase) \
  (1 & (intptr_t) ABLOCKS_BUSY (abase) ? abase : ((void **) (abase))[-1])
#endif

static struct ablock *free_ablock;

/* Allocate an aligned block of NBYTES.  */
static void *
lisp_align_malloc (size_t nbytes, enum mem_type type)
{
  void *base, *val;
  struct ablocks *abase;

  eassert (nbytes < BLOCK_ALIGN);

#ifdef GC_MALLOC_CHECK
  allocated_mem_type = type;
#endif

  if (! free_ablock)
    {
      int i;
      bool aligned;

#ifdef USE_ALIGNED_ALLOC
      abase = base = aligned_alloc (BLOCK_ALIGN, sizeof (struct ablocks));
#else
      base = malloc (sizeof (struct ablocks));
      abase = pointer_align (base, BLOCK_ALIGN);
#endif

      if (! base)
	memory_full (sizeof (struct ablocks));

      aligned = (base == abase);
      if (! aligned)
	((void **) abase)[-1] = base;

#if ! USE_LSB_TAG
      /* If the memory just allocated cannot be addressed thru a Lisp
	 object's pointer, and it needs to be, that's equivalent to
	 running out of memory.  */
      if (type != MEM_TYPE_NON_LISP)
	{
	  Lisp_Object tem;
	  char *end = (char *) base + sizeof (struct ablocks) - 1;
	  XSETCONS (tem, end);
	  if ((char *) XCONS (tem) != end)
	    {
	      lisp_malloc_loser = base;
	      free (base);
	      memory_full (SIZE_MAX);
	    }
	}
#endif

      /* Initialize the blocks and put them on the free list.
	 If BASE was not properly aligned, we can't use the last block.  */
      for (i = 0; i < (aligned ? ABLOCKS_NBLOCKS : ABLOCKS_NBLOCKS - 1); ++i)
	{
	  abase->blocks[i].abase = abase;
	  abase->blocks[i].x.next_free = free_ablock;
	  free_ablock = &abase->blocks[i];
	}
      intptr_t ialigned = aligned;
      ABLOCKS_BUSY (abase) = (struct ablocks *) ialigned;

      eassert ((uintptr_t) abase % BLOCK_ALIGN == 0);
      eassert (ABLOCK_ABASE (&abase->blocks[3]) == abase); /* 3 is arbitrary */
      eassert (ABLOCK_ABASE (&abase->blocks[0]) == abase);
      eassert (ABLOCKS_BASE (abase) == base);
      eassert ((intptr_t) ABLOCKS_BUSY (abase) == aligned);
    }

  abase = ABLOCK_ABASE (free_ablock);
  ABLOCKS_BUSY (abase)
    = (struct ablocks *) (2 + (intptr_t) ABLOCKS_BUSY (abase));
  val = free_ablock;
  free_ablock = free_ablock->x.next_free;

#ifndef GC_MALLOC_CHECK
  if (type != MEM_TYPE_NON_LISP)
    mem_insert (val, (char *) val + nbytes, type);
#endif

  MALLOC_PROBE (nbytes);

  eassert (0 == ((uintptr_t) val) % BLOCK_ALIGN);
  return val;
}

static void
lisp_align_free (void *block)
{
  struct ablock *ablock = block;
  struct ablocks *abase = ABLOCK_ABASE (ablock);

#ifndef GC_MALLOC_CHECK
  mem_delete (mem_find (block));
#endif
  /* Put on free list.  */
  ablock->x.next_free = free_ablock;
  free_ablock = ablock;
  /* Update busy count.  */
  intptr_t busy = (intptr_t) ABLOCKS_BUSY (abase) - 2;
  eassume (0 <= busy && busy <= 2 * ABLOCKS_NBLOCKS - 1);
  ABLOCKS_BUSY (abase) = (struct ablocks *) busy;

  if (busy < 2)
    { /* All the blocks are free.  */
      int i = 0;
      bool aligned = busy;
      struct ablock **tem = &free_ablock;
      struct ablock *atop = &abase->blocks[aligned ? ABLOCKS_NBLOCKS : ABLOCKS_NBLOCKS - 1];

      while (*tem)
	{
	  if (*tem >= (struct ablock *) abase && *tem < atop)
	    {
	      i++;
	      *tem = (*tem)->x.next_free;
	    }
	  else
	    tem = &(*tem)->x.next_free;
	}
      eassert ((aligned & 1) == aligned);
      eassert (i == (aligned ? ABLOCKS_NBLOCKS : ABLOCKS_NBLOCKS - 1));
#ifdef USE_POSIX_MEMALIGN
      eassert ((uintptr_t) ABLOCKS_BASE (abase) % BLOCK_ALIGN == 0);
#endif
      free (ABLOCKS_BASE (abase));
    }
}

struct interval_block
{
  /* Place INTERVALS first, to preserve alignment.  */
  struct interval intervals[BLOCK_NINTERVALS];
  struct interval_block *next;
};

static struct interval_block *interval_block;
static int interval_block_index = BLOCK_NINTERVALS;
static INTERVAL interval_free_list;

INTERVAL
make_interval (void)
{
  INTERVAL val;

  if (interval_free_list)
    {
      val = interval_free_list;
      interval_free_list = INTERVAL_PARENT (interval_free_list);
    }
  else
    {
      if (interval_block_index == BLOCK_NINTERVALS)
	{
	  struct interval_block *newi
	    = lisp_malloc (sizeof *newi, false, MEM_TYPE_NON_LISP);

	  newi->next = interval_block;
	  interval_block = newi;
	  interval_block_index = 0;
	}
      val = &interval_block->intervals[interval_block_index++];
    }

  bytes_since_gc += sizeof (struct interval);
  intervals_consed++;
  RESET_INTERVAL (val);
  val->gcmarkbit = 0;
  return val;
}

/* Correct functional form for traverse_intervals_noorder().  */

static void
mark_interval_tree_1 (INTERVAL i, void *dummy)
{
  eassert (! interval_marked_p (i));
  set_interval_marked (i);
  mark_object (i->plist);
}

/* Mark the interval tree rooted in I.  */

static void
mark_interval_tree (INTERVAL i)
{
  if (i && ! interval_marked_p (i))
    traverse_intervals_noorder (i, mark_interval_tree_1, NULL);
}

/* Lisp_Strings are allocated in string_block structures.  When a new
   string_block is allocated, all the Lisp_Strings it contains are
   added to a free list string_free_list.  When a new Lisp_String is
   needed, it is taken from that list.  During the sweep phase of GC,
   string_blocks that are entirely free are freed, except two which
   we keep.

   String data is allocated from sblock structures.  Strings larger
   than LARGE_STRING_BYTES, get their own sblock, data for smaller
   strings is sub-allocated out of sblocks of size SBLOCK_SIZE.

   Sblocks consist internally of sdata structures, one for each
   Lisp_String.  The sdata structure points to the Lisp_String it
   belongs to.  The Lisp_String points back to the `u.data' member of
   its sdata structure.

   When a Lisp_String is freed during GC, it is put back on
   string_free_list, and its DATA member and its sdata's STRING
   pointer are set to null.  The size of the string is recorded in the
   N.NBYTES member of the sdata.  So, sdata structures that are no
   longer used, can be easily recognized, and it's easy to compact the
   sblocks of small strings which we do in compact_small_strings.  */

/* Size in bytes of an sblock structure used for small strings.  */

#define SBLOCK_SIZE (MALLOC_SIZE_NEAR(1 << 13))

/* Large string are allocated from individual sblocks.  */

#define LARGE_STRING_BYTES (1 << 10)

struct sdata
{
  /* Back-pointer to the string this sdata belongs to.  If null, this
     structure is free, and NBYTES (in this structure or in the union below)
     contains the string's byte size (the same value that STRING_BYTES
     would return if STRING were non-null).  If non-null, STRING_BYTES
     (STRING) is the size of the data, and DATA contains the string's
     contents.  */
  struct Lisp_String *string;

#ifdef GC_CHECK_STRING_BYTES
  ptrdiff_t nbytes;
#endif

  unsigned char data[FLEXIBLE_ARRAY_MEMBER];
};

/* A union describing string memory sub-allocated from an sblock.
   This is where the contents of Lisp strings are stored.  */

typedef union
{
  struct Lisp_String *string;

  /* When STRING is null.  */
  struct
  {
    struct Lisp_String *string;
    ptrdiff_t nbytes;
  } n;
} sdata;

#define SDATA_NBYTES(S)	(S)->n.nbytes
#define SDATA_DATA(S)	((struct sdata *) (S))->data

enum { SDATA_DATA_OFFSET = offsetof (struct sdata, data) };

/* Structure describing a block of memory which is sub-allocated to
   obtain string data memory for strings.  Blocks for small strings
   are of fixed size SBLOCK_SIZE.  Blocks for large strings are made
   as large as needed.  */

struct sblock
{
  /* Next in list.  */
  struct sblock *next;

  /* Pointer to the next free sdata block.  This points past the end
     of the sblock if there isn't any space left in this block.  */
  sdata *next_free;

  /* String data.  */
  sdata data[FLEXIBLE_ARRAY_MEMBER];
};

struct string_block
{
  /* Data first, to preserve alignment.  */
  struct Lisp_String strings[BLOCK_NSTRINGS];
  struct string_block *next;
};

/* Head and tail of the list of sblock structures holding Lisp string
   data.  We always allocate from current_sblock.  The NEXT pointers
   in the sblock structures go from oldest_sblock to current_sblock.  */

static struct sblock *oldest_sblock, *current_sblock;
static struct sblock *large_sblocks;
static struct string_block *string_blocks;
static struct Lisp_String *string_free_list;

/* Given a pointer to a Lisp_String S which is on string_free_list,
   return a pointer to its successor in the free list.  */

#define NEXT_FREE_LISP_STRING(S) ((S)->u.next)

/* Return a pointer to the sdata structure belonging to Lisp string S.
   S must be live, i.e. S->data must not be null.  S->data is actually
   a pointer to the `u.data' member of its sdata structure; the
   structure starts at a constant offset in front of that.  */

#define SDATA_OF_STRING(S) ((sdata *) ((S)->u.s.data - SDATA_DATA_OFFSET))


#ifdef GC_CHECK_STRING_OVERRUN

/* Check for overrun in string data blocks by appending a small
   "cookie" after each allocated string data block, and check for the
   presence of this cookie during GC.  */
# define GC_STRING_OVERRUN_COOKIE_SIZE ROUNDUP (4, alignof (sdata))
static char const string_overrun_cookie[GC_STRING_OVERRUN_COOKIE_SIZE] =
  { '\xde', '\xad', '\xbe', '\xef', /* Perhaps some zeros here.  */ };

#else
# define GC_STRING_OVERRUN_COOKIE_SIZE 0
#endif

/* Return the size of an sdata structure large enough to hold N bytes
   of string data.  This counts the sdata structure, the N bytes, a
   terminating NUL byte, and alignment padding.  */

static ptrdiff_t
sdata_size (ptrdiff_t n)
{
  /* Reserve space for the nbytes union member even when N + 1 is less
     than the size of that member.  */
  ptrdiff_t unaligned_size = max (SDATA_DATA_OFFSET + n + 1,
				  sizeof (sdata));
  int sdata_align = max (FLEXALIGNOF (struct sdata), alignof (sdata));
  return (unaligned_size + sdata_align - 1) & ~(sdata_align - 1);
}

/* Extra bytes to allocate for each string.  */
#define GC_STRING_EXTRA GC_STRING_OVERRUN_COOKIE_SIZE

/* Exact bound on the number of bytes in a string, not counting the
   terminating null.  A string cannot contain more bytes than
   STRING_BYTES_BOUND, nor can it be so long that the size_t
   arithmetic in allocate_string_data would overflow while it is
   calculating a value to be passed to malloc.  */
static ptrdiff_t const STRING_BYTES_MAX =
  min (STRING_BYTES_BOUND,
       ((SIZE_MAX
	 - GC_STRING_EXTRA
	 - offsetof (struct sblock, data)
	 - SDATA_DATA_OFFSET)
	& ~(sizeof (EMACS_INT) - 1)));

static void
init_strings (void)
{
  empty_unibyte_string = make_pure_string ("", 0, 0, 0);
  staticpro (&empty_unibyte_string);
  empty_multibyte_string = make_pure_string ("", 0, 0, 1);
  staticpro (&empty_multibyte_string);
}


#ifdef GC_CHECK_STRING_BYTES

static int check_string_bytes_count;

/* Like STRING_BYTES, but with debugging check.  Can be
   called during GC, so pay attention to the mark bit.  */

ptrdiff_t
string_bytes (struct Lisp_String *s)
{
  ptrdiff_t nbytes =
    (s->u.s.size_byte < 0 ? s->u.s.size & ~ARRAY_MARK_FLAG : s->u.s.size_byte);

  if (! PURE_P (s) && ! pdumper_object_p (s) && s->u.s.data
      && nbytes != SDATA_NBYTES (SDATA_OF_STRING (s)))
    emacs_abort ();
  return nbytes;
}

/* Check validity of Lisp strings' string_bytes member in B.  */

static void
check_sblock (struct sblock *b)
{
  for (sdata *from = b->data, end =  b->next_free; from < end; )
    {
      ptrdiff_t nbytes = sdata_size (from->string
				     ? string_bytes (from->string)
				     : SDATA_NBYTES (from));
      from = (sdata *) ((char *) from + nbytes + GC_STRING_EXTRA);
    }
}


/* Check validity of Lisp strings' string_bytes member.  ALL_P
   means check all strings, otherwise check only most
   recently allocated strings.  Used for hunting a bug.  */

static void
check_string_bytes (bool all_p)
{
  if (all_p)
    {
      struct sblock *b;

      for (b = large_sblocks; b; b = b->next)
	{
	  struct Lisp_String *s = b->data[0].string;
	  if (s)
	    string_bytes (s);
	}

      for (b = oldest_sblock; b; b = b->next)
	check_sblock (b);
    }
  else if (current_sblock)
    check_sblock (current_sblock);
}

#else /* not GC_CHECK_STRING_BYTES */

#define check_string_bytes(all) ((void) 0)

#endif /* GC_CHECK_STRING_BYTES */

#ifdef GC_CHECK_STRING_FREE_LIST

/* Walk through the string free list looking for bogus next pointers.
   This may catch buffer overrun from a previous string.  */

static void
check_string_free_list (void)
{
  struct Lisp_String *s;

  /* Pop a Lisp_String off the free list.  */
  s = string_free_list;
  while (s != NULL)
    {
      if ((uintptr_t) s < BLOCK_ALIGN)
	emacs_abort ();
      s = NEXT_FREE_LISP_STRING (s);
    }
}
#else
#define check_string_free_list()
#endif

/* Return a new Lisp_String.  */

static struct Lisp_String *
allocate_string (void)
{
  struct Lisp_String *s;

  /* If the free list is empty, allocate a new string_block, and
     add all the Lisp_Strings in it to the free list.  */
  if (string_free_list == NULL)
    {
      struct string_block *b = lisp_malloc (sizeof *b, false, MEM_TYPE_STRING);
      int i;

      b->next = string_blocks;
      string_blocks = b;

      for (i = BLOCK_NSTRINGS - 1; i >= 0; --i)
	{
	  s = b->strings + i;
	  /* Every string on a free list should have NULL data pointer.  */
	  s->u.s.data = NULL;
	  NEXT_FREE_LISP_STRING (s) = string_free_list;
	  string_free_list = s;
	}
    }

  check_string_free_list ();

  /* Pop a Lisp_String off the free list.  */
  s = string_free_list;
  string_free_list = NEXT_FREE_LISP_STRING (s);

  ++strings_consed;
  bytes_since_gc += sizeof *s;

#ifdef GC_CHECK_STRING_BYTES
  if (! noninteractive)
    {
      if (++check_string_bytes_count == 200)
	{
	  check_string_bytes_count = 0;
	  check_string_bytes (1);
	}
      else
	check_string_bytes (0);
    }
#endif /* GC_CHECK_STRING_BYTES */

  return s;
}

/* Set up Lisp_String S for holding NCHARS characters, NBYTES bytes,
   plus a NUL byte at the end.  Allocate an sdata structure DATA for
   S, and set S->u.s.data to SDATA->u.data.  Store a NUL byte at the
   end of S->u.s.data.  Set S->u.s.size to NCHARS and S->u.s.size_byte
   to NBYTES.  Free S->u.s.data if it was initially non-null.

   If Q_CLEAR, also clear the other bytes of S->u.s.data.  */

static void
allocate_string_data (struct Lisp_String *s,
		      EMACS_INT nchars, EMACS_INT nbytes, bool q_clear,
		      bool immovable)
{
  sdata *data;
  struct sblock *b;

  if (STRING_BYTES_MAX < nbytes)
    string_overflow ();

  /* Determine the number of bytes needed to store NBYTES bytes
     of string data.  */
  ptrdiff_t needed = sdata_size (nbytes);

  if (nbytes > LARGE_STRING_BYTES || immovable)
    {
      size_t size = FLEXSIZEOF (struct sblock, data, needed);
      b = lisp_malloc (size + GC_STRING_EXTRA, q_clear, MEM_TYPE_NON_LISP);
      data = b->data;
      b->next = large_sblocks;
      b->next_free = data;
      large_sblocks = b;
    }
  else
    {
      b = current_sblock;

      if (b == NULL
	  || (SBLOCK_SIZE - GC_STRING_EXTRA
	      < (char *) b->next_free - (char *) b + needed))
	{
	  /* Not enough room in the current sblock.  */
	  b = lisp_malloc (SBLOCK_SIZE, false, MEM_TYPE_NON_LISP);
	  data = b->data;
	  b->next = NULL;
	  b->next_free = data;

	  if (current_sblock)
	    current_sblock->next = b;
	  else
	    oldest_sblock = b;
	  current_sblock = b;
	}

      data = b->next_free;
      if (q_clear)
	memset (SDATA_DATA (data), 0, nbytes);
    }

  data->string = s;
  b->next_free = (sdata *) ((char *) data + needed + GC_STRING_EXTRA);
  eassert ((uintptr_t) b->next_free % alignof (sdata) == 0);

  s->u.s.data = SDATA_DATA (data);
#ifdef GC_CHECK_STRING_BYTES
  SDATA_NBYTES (data) = nbytes;
#endif
  s->u.s.size = nchars;
  s->u.s.size_byte = nbytes;
  s->u.s.data[nbytes] = '\0';
#ifdef GC_CHECK_STRING_OVERRUN
  memcpy ((char *) data + needed, string_overrun_cookie,
	  GC_STRING_OVERRUN_COOKIE_SIZE);
#endif

  bytes_since_gc += needed;
}

/* Reallocate multibyte STRING data when a single character is replaced.
   The character is at byte offset CIDX_BYTE in the string.
   The character being replaced is CLEN bytes long,
   and the character that will replace it is NEW_CLEN bytes long.
   Return the address where the caller should store the new character.  */

unsigned char *
resize_string_data (Lisp_Object string, ptrdiff_t cidx_byte,
		    int clen, int new_clen)
{
  eassume (STRING_MULTIBYTE (string));
  sdata *old_sdata = SDATA_OF_STRING (XSTRING (string));
  ptrdiff_t nchars = SCHARS (string);
  ptrdiff_t nbytes = SBYTES (string);
  ptrdiff_t new_nbytes = nbytes + (new_clen - clen);
  unsigned char *data = SDATA (string);
  unsigned char *new_charaddr;

  if (sdata_size (nbytes) == sdata_size (new_nbytes))
    {
      /* No need to reallocate, as the size change falls within the
	 alignment slop.  */
      XSTRING (string)->u.s.size_byte = new_nbytes;
#ifdef GC_CHECK_STRING_BYTES
      SDATA_NBYTES (old_sdata) = new_nbytes;
#endif
      new_charaddr = data + cidx_byte;
      memmove (new_charaddr + new_clen, new_charaddr + clen,
	       nbytes - (cidx_byte + (clen - 1)));
    }
  else
    {
      allocate_string_data (XSTRING (string), nchars, new_nbytes, false, false);
      unsigned char *new_data = SDATA (string);
      new_charaddr = new_data + cidx_byte;
      memcpy (new_charaddr + new_clen, data + cidx_byte + clen,
	      nbytes - (cidx_byte + clen));
      memcpy (new_data, data, cidx_byte);

      /* Mark old string data as free by setting its string back-pointer
	 to null, and record the size of the data in it.  */
      SDATA_NBYTES (old_sdata) = nbytes;
      old_sdata->string = NULL;
    }

  clear_string_char_byte_cache ();

  return new_charaddr;
}


/* Sweep and compact strings.  */

static void
sweep_strings (void)
{
  struct string_block *b, *next;
  struct string_block *live_blocks = NULL;

  string_free_list = NULL;
  gcstat.total_string_bytes = gcstat.total_strings
    = gcstat.total_free_strings = 0;

  /* Scan strings_blocks, free Lisp_Strings that aren't marked.  */
  for (b = string_blocks; b; b = next)
    {
      int i, nfree = 0;
      struct Lisp_String *free_list_before = string_free_list;

      next = b->next;

      for (i = 0; i < BLOCK_NSTRINGS; ++i)
	{
	  struct Lisp_String *s = b->strings + i;

	  if (s->u.s.data)
	    {
	      /* String was not on free list before.  */
	      if (XSTRING_MARKED_P (s))
		{
		  /* String is live; unmark it and its intervals.  */
		  XUNMARK_STRING (s);

		  /* Do not use string_(set|get)_intervals here.  */
		  s->u.s.intervals = balance_intervals (s->u.s.intervals);

		  gcstat.total_strings++;
		  gcstat.total_string_bytes += STRING_BYTES (s);
		}
	      else
		{
		  /* String is dead.  Put it on the free list.  */
		  sdata *data = SDATA_OF_STRING (s);

		  /* Save the size of S in its sdata so that we know
		     how large that is.  Reset the sdata's string
		     back-pointer so that we know it's free.  */
#ifdef GC_CHECK_STRING_BYTES
		  if (string_bytes (s) != SDATA_NBYTES (data))
		    emacs_abort ();
#else
		  data->n.nbytes = STRING_BYTES (s);
#endif
		  data->string = NULL;

		  /* Reset the strings's `data' member so that we
		     know it's free.  */
		  s->u.s.data = NULL;

		  /* Put the string on the free list.  */
		  NEXT_FREE_LISP_STRING (s) = string_free_list;
		  string_free_list = s;
		  ++nfree;
		}
	    }
	  else
	    {
	      /* S was on the free list before.  Put it there again.  */
	      NEXT_FREE_LISP_STRING (s) = string_free_list;
	      string_free_list = s;
	      ++nfree;
	    }
	}

      /* Free blocks that contain free Lisp_Strings only, except
	 the first two of them.  */
      if (nfree == BLOCK_NSTRINGS
	  && gcstat.total_free_strings > BLOCK_NSTRINGS)
	{
	  lisp_free (b);
	  string_free_list = free_list_before;
	}
      else
	{
	  gcstat.total_free_strings += nfree;
	  b->next = live_blocks;
	  live_blocks = b;
	}
    }

  check_string_free_list ();

  string_blocks = live_blocks;
  free_large_strings ();
  compact_small_strings ();

  check_string_free_list ();
}

static void
free_large_strings (void)
{
  struct sblock *b, *next;
  struct sblock *live_blocks = NULL;

  for (b = large_sblocks; b; b = next)
    {
      next = b->next;

      if (b->data[0].string == NULL)
	lisp_free (b);
      else
	{
	  b->next = live_blocks;
	  live_blocks = b;
	}
    }

  large_sblocks = live_blocks;
}

/* Compact data of small strings.  Free sblocks that don't contain
   data of live strings after compaction.  */

static void
compact_small_strings (void)
{
  /* TB is the sblock we copy to, TO is the sdata within TB we copy
     to, and TB_END is the end of TB.  */
  struct sblock *tb = oldest_sblock;
  if (tb)
    {
      sdata *tb_end = (sdata *) ((char *) tb + SBLOCK_SIZE);
      sdata *to = tb->data;

      /* Step through the blocks from the oldest to the youngest.  We
	 expect that old blocks will stabilize over time, so that less
	 copying will happen this way.  */
      struct sblock *b = tb;
      do
	{
	  sdata *end = b->next_free;
	  eassert ((char *) end <= (char *) b + SBLOCK_SIZE);

	  for (sdata *from = b->data; from < end; )
	    {
	      /* Compute the next FROM here because copying below may
		 overwrite data we need to compute it.  */
	      ptrdiff_t nbytes;
	      struct Lisp_String *s = from->string;

#ifdef GC_CHECK_STRING_BYTES
	      /* Check that the string size recorded in the string is the
		 same as the one recorded in the sdata structure.  */
	      if (s && string_bytes (s) != SDATA_NBYTES (from))
		emacs_abort ();
#endif /* GC_CHECK_STRING_BYTES */

	      nbytes = s ? STRING_BYTES (s) : SDATA_NBYTES (from);
	      eassert (nbytes <= LARGE_STRING_BYTES);

	      ptrdiff_t size = sdata_size (nbytes);
	      sdata *from_end = (sdata *) ((char *) from
					   + size + GC_STRING_EXTRA);

#ifdef GC_CHECK_STRING_OVERRUN
	      if (memcmp (string_overrun_cookie,
			  (char *) from_end - GC_STRING_OVERRUN_COOKIE_SIZE,
			  GC_STRING_OVERRUN_COOKIE_SIZE))
		emacs_abort ();
#endif

	      /* Non-NULL S means it's alive.  Copy its data.  */
	      if (s)
		{
		  /* If TB is full, proceed with the next sblock.  */
		  sdata *to_end = (sdata *) ((char *) to
					     + size + GC_STRING_EXTRA);
		  if (to_end > tb_end)
		    {
		      tb->next_free = to;
		      tb = tb->next;
		      tb_end = (sdata *) ((char *) tb + SBLOCK_SIZE);
		      to = tb->data;
		      to_end = (sdata *) ((char *) to + size + GC_STRING_EXTRA);
		    }

		  /* Copy, and update the string's `data' pointer.  */
		  if (from != to)
		    {
		      eassert (tb != b || to < from);
		      memmove (to, from, size + GC_STRING_EXTRA);
		      to->string->u.s.data = SDATA_DATA (to);
		    }

		  /* Advance past the sdata we copied to.  */
		  to = to_end;
		}
	      from = from_end;
	    }
	  b = b->next;
	}
      while (b);

      /* The rest of the sblocks following TB don't contain live data, so
	 we can free them.  */
      for (b = tb->next; b; )
	{
	  struct sblock *next = b->next;
	  lisp_free (b);
	  b = next;
	}

      tb->next_free = to;
      tb->next = NULL;
    }

  current_sblock = tb;
}

void
string_overflow (void)
{
  error ("Maximum string size exceeded");
}

static Lisp_Object make_clear_string (EMACS_INT, bool);
static Lisp_Object make_clear_multibyte_string (EMACS_INT, EMACS_INT, bool);

DEFUN ("make-string", Fmake_string, Smake_string, 2, 3, 0,
       doc: /* Return a newly created string of length LENGTH, with INIT in each element.
LENGTH must be an integer.
INIT must be an integer that represents a character.
If optional argument MULTIBYTE is non-nil, the result will be
a multibyte string even if INIT is an ASCII character.  */)
  (Lisp_Object length, Lisp_Object init, Lisp_Object multibyte)
{
  Lisp_Object val;
  EMACS_INT nbytes;

  CHECK_FIXNAT (length);
  CHECK_CHARACTER (init);

  int c = XFIXNAT (init);
  bool q_clear = !c;

  if (ASCII_CHAR_P (c) && NILP (multibyte))
    {
      nbytes = XFIXNUM (length);
      val = make_clear_string (nbytes, q_clear);
      if (nbytes && !q_clear)
	{
	  memset (SDATA (val), c, nbytes);
	  SDATA (val)[nbytes] = 0;
	}
    }
  else
    {
      unsigned char str[MAX_MULTIBYTE_LENGTH];
      ptrdiff_t len = CHAR_STRING (c, str);
      EMACS_INT string_len = XFIXNUM (length);

      if (INT_MULTIPLY_WRAPV (len, string_len, &nbytes))
	string_overflow ();
      val = make_clear_multibyte_string (string_len, nbytes, q_clear);
      if (!q_clear)
	{
	  unsigned char *beg = SDATA (val), *end = beg + nbytes;
	  for (unsigned char *p = beg; p < end; p += len)
	    {
	      /* First time we just copy STR to the data of VAL.  */
	      if (p == beg)
		memcpy (p, str, len);
	      else
		{
		  /* Next time we copy largest possible chunk from
		     initialized to uninitialized part of VAL.  */
		  len = min (p - beg, end - p);
		  memcpy (p, beg, len);
		}
	    }
	}
    }

  return val;
}

/* Fill A with 1 bits if INIT is non-nil, and with 0 bits otherwise.
   Return A.  */

Lisp_Object
bool_vector_fill (Lisp_Object a, Lisp_Object init)
{
  EMACS_INT nbits = bool_vector_size (a);
  if (0 < nbits)
    {
      unsigned char *data = bool_vector_uchar_data (a);
      int pattern = NILP (init) ? 0 : (1 << BOOL_VECTOR_BITS_PER_CHAR) - 1;
      ptrdiff_t nbytes = bool_vector_bytes (nbits);
      int last_mask = ~ (~0u << ((nbits - 1) % BOOL_VECTOR_BITS_PER_CHAR + 1));
      memset (data, pattern, nbytes - 1);
      data[nbytes - 1] = pattern & last_mask;
    }
  return a;
}

/* Return a newly allocated, uninitialized bool vector of size NBITS.  */

Lisp_Object
make_uninit_bool_vector (EMACS_INT nbits)
{
  Lisp_Object val;
  EMACS_INT words = bool_vector_words (nbits);
  EMACS_INT word_bytes = words * sizeof (bits_word);
  EMACS_INT needed_elements = ((bool_header_size - header_size + word_bytes
				+ word_size - 1)
			       / word_size);
  if (PTRDIFF_MAX < needed_elements)
    memory_full (SIZE_MAX);
  struct Lisp_Bool_Vector *p
    = (struct Lisp_Bool_Vector *) allocate_vectorlike (needed_elements, false);
  XSETVECTOR (val, p);
  XSETPVECTYPESIZE (XVECTOR (val), PVEC_BOOL_VECTOR, 0, 0);
  p->size = nbits;

  /* Clear padding at the end.  */
  if (words)
    p->data[words - 1] = 0;

  return val;
}

DEFUN ("make-bool-vector", Fmake_bool_vector, Smake_bool_vector, 2, 2, 0,
       doc: /* Return a new bool-vector of length LENGTH, using INIT for each element.
LENGTH must be a number.  INIT matters only in whether it is t or nil.  */)
  (Lisp_Object length, Lisp_Object init)
{
  Lisp_Object val;

  CHECK_FIXNAT (length);
  val = make_uninit_bool_vector (XFIXNAT (length));
  return bool_vector_fill (val, init);
}

DEFUN ("bool-vector", Fbool_vector, Sbool_vector, 0, MANY, 0,
       doc: /* Return a new bool-vector with specified arguments as elements.
Allows any number of arguments, including zero.
usage: (bool-vector &rest OBJECTS)  */)
  (ptrdiff_t nargs, Lisp_Object *args)
{
  ptrdiff_t i;
  Lisp_Object vector;

  vector = make_uninit_bool_vector (nargs);
  for (i = 0; i < nargs; i++)
    bool_vector_set (vector, i, ! NILP (args[i]));

  return vector;
}

/* Make a string from NBYTES bytes at CONTENTS, and compute the number
   of characters from the contents.  This string may be unibyte or
   multibyte, depending on the contents.  */

Lisp_Object
make_string (const char *contents, ptrdiff_t nbytes)
{
  register Lisp_Object val;
  ptrdiff_t nchars, multibyte_nbytes;

  parse_str_as_multibyte ((const unsigned char *) contents, nbytes,
			  &nchars, &multibyte_nbytes);
  if (nbytes == nchars || nbytes != multibyte_nbytes)
    /* CONTENTS contains no multibyte sequences or contains an invalid
       multibyte sequence.  We must make unibyte string.  */
    val = make_unibyte_string (contents, nbytes);
  else
    val = make_multibyte_string (contents, nchars, nbytes);
  return val;
}

/* Make a unibyte string from LENGTH bytes at CONTENTS.  */

Lisp_Object
make_unibyte_string (const char *contents, ptrdiff_t length)
{
  register Lisp_Object val;
  val = make_uninit_string (length);
  memcpy (SDATA (val), contents, length);
  return val;
}

/* Make a multibyte string from NCHARS characters occupying NBYTES
   bytes at CONTENTS.  */

Lisp_Object
make_multibyte_string (const char *contents,
		       ptrdiff_t nchars, ptrdiff_t nbytes)
{
  register Lisp_Object val;
  val = make_uninit_multibyte_string (nchars, nbytes);
  memcpy (SDATA (val), contents, nbytes);
  return val;
}

/* Make a string from NCHARS characters occupying NBYTES bytes at
   CONTENTS.  It is a multibyte string if NBYTES != NCHARS.  */

Lisp_Object
make_string_from_bytes (const char *contents,
			ptrdiff_t nchars, ptrdiff_t nbytes)
{
  register Lisp_Object val;
  val = make_uninit_multibyte_string (nchars, nbytes);
  memcpy (SDATA (val), contents, nbytes);
  if (SBYTES (val) == SCHARS (val))
    STRING_SET_UNIBYTE (val);
  return val;
}

/* Make a string from NCHARS characters occupying NBYTES bytes at
   CONTENTS.  The argument MULTIBYTE controls whether to label the
   string as multibyte.  If NCHARS is negative, it counts the number of
   characters by itself.  */

Lisp_Object
make_specified_string (const char *contents,
		       ptrdiff_t nchars, ptrdiff_t nbytes, bool multibyte)
{
  Lisp_Object val;

  if (nchars < 0)
    {
      if (multibyte)
	nchars = multibyte_chars_in_text ((const unsigned char *) contents,
					  nbytes);
      else
	nchars = nbytes;
    }
  val = make_uninit_multibyte_string (nchars, nbytes);
  memcpy (SDATA (val), contents, nbytes);
  if (!multibyte)
    STRING_SET_UNIBYTE (val);
  return val;
}

/* Return a unibyte Lisp_String set up to hold LENGTH characters
   occupying LENGTH bytes.  If Q_CLEAR, clear its contents to null
   bytes; otherwise, the contents are uninitialized.  */

static Lisp_Object
make_clear_string (EMACS_INT length, bool q_clear)
{
  Lisp_Object val;

  if (!length)
    return empty_unibyte_string;
  val = make_clear_multibyte_string (length, length, q_clear);
  STRING_SET_UNIBYTE (val);
  return val;
}

/* Return a unibyte Lisp_String set up to hold LENGTH characters
   occupying LENGTH bytes.  */

Lisp_Object
make_uninit_string (EMACS_INT length)
{
  return make_clear_string (length, false);
}

/* Return a multibyte Lisp_String set up to hold NCHARS characters
   which occupy NBYTES bytes.  If Q_CLEAR, clear its contents to null
   bytes; otherwise, the contents are uninitialized.  */

static Lisp_Object
make_clear_multibyte_string (EMACS_INT nchars, EMACS_INT nbytes, bool q_clear)
{
  Lisp_Object string;
  struct Lisp_String *s;

  if (nchars < 0)
    emacs_abort ();
  if (!nbytes)
    return empty_multibyte_string;

  s = allocate_string ();
  s->u.s.intervals = NULL;
  allocate_string_data (s, nchars, nbytes, q_clear, false);
  XSETSTRING (string, s);
  string_chars_consed += nbytes;
  return string;
}

/* Return a multibyte Lisp_String set up to hold NCHARS characters
   which occupy NBYTES bytes.  */

Lisp_Object
make_uninit_multibyte_string (EMACS_INT nchars, EMACS_INT nbytes)
{
  return make_clear_multibyte_string (nchars, nbytes, false);
}

/* Print arguments to BUF according to a FORMAT, then return
   a Lisp_String initialized with the data from BUF.  */

Lisp_Object
make_formatted_string (char *buf, const char *format, ...)
{
  va_list ap;
  int length;

  va_start (ap, format);
  length = vsprintf (buf, format, ap);
  va_end (ap);
  return make_string (buf, length);
}

/* Pin a unibyte string in place so that it won't move during GC.  */
void
pin_string (Lisp_Object string)
{
  eassert (STRINGP (string) && !STRING_MULTIBYTE (string));
  struct Lisp_String *s = XSTRING (string);
  ptrdiff_t size = STRING_BYTES (s);
  unsigned char *data = s->u.s.data;

  if (!(size > LARGE_STRING_BYTES
	|| PURE_P (data) || pdumper_object_p (data)
	|| s->u.s.size_byte == -3))
    {
      eassert (s->u.s.size_byte == -1);
      sdata *old_sdata = SDATA_OF_STRING (s);
      allocate_string_data (s, size, size, false, true);
      memcpy (s->u.s.data, data, size);
      old_sdata->string = NULL;
      SDATA_NBYTES (old_sdata) = size;
    }
  s->u.s.size_byte = -3;
}

#define GETMARKBIT(block,n)				\
  (((block)->gcmarkbits[(n) / BITS_PER_BITS_WORD]	\
    >> ((n) % BITS_PER_BITS_WORD))			\
   & 1)

#define SETMARKBIT(block,n)				\
  ((block)->gcmarkbits[(n) / BITS_PER_BITS_WORD]	\
   |= (bits_word) 1 << ((n) % BITS_PER_BITS_WORD))

#define UNSETMARKBIT(block,n)				\
  ((block)->gcmarkbits[(n) / BITS_PER_BITS_WORD]	\
   &= ~((bits_word) 1 << ((n) % BITS_PER_BITS_WORD)))

#define FLOAT_BLOCK(fptr) \
  (eassert (! pdumper_object_p (fptr)),                                  \
   ((struct float_block *) (((uintptr_t) (fptr)) & ~(BLOCK_ALIGN - 1))))

#define FLOAT_INDEX(fptr) \
  ((((uintptr_t) (fptr)) & (BLOCK_ALIGN - 1)) / sizeof (struct Lisp_Float))

struct float_block
{
  /* Data first, to preserve alignment.  */
  struct Lisp_Float floats[BLOCK_NFLOATS];
  bits_word gcmarkbits[1 + BLOCK_NFLOATS / BITS_PER_BITS_WORD];
  struct float_block *next;
};

#define XFLOAT_MARKED_P(fptr) \
  GETMARKBIT (FLOAT_BLOCK (fptr), FLOAT_INDEX ((fptr)))

#define XFLOAT_MARK(fptr) \
  SETMARKBIT (FLOAT_BLOCK (fptr), FLOAT_INDEX ((fptr)))

#define XFLOAT_UNMARK(fptr) \
  UNSETMARKBIT (FLOAT_BLOCK (fptr), FLOAT_INDEX ((fptr)))

static struct float_block *float_block;
static int float_block_index = BLOCK_NFLOATS;
static struct Lisp_Float *float_free_list;

Lisp_Object
make_float (double float_value)
{
  register Lisp_Object val;

  if (float_free_list)
    {
      XSETFLOAT (val, float_free_list);
      float_free_list = float_free_list->u.chain;
    }
  else
    {
      if (float_block_index == BLOCK_NFLOATS)
	{
	  struct float_block *new
	    = lisp_align_malloc (sizeof *new, MEM_TYPE_FLOAT);
	  new->next = float_block;
	  memset (new->gcmarkbits, 0, sizeof new->gcmarkbits);
	  float_block = new;
	  float_block_index = 0;
	}
      XSETFLOAT (val, &float_block->floats[float_block_index]);
      float_block_index++;
    }

  XFLOAT_INIT (val, float_value);
  eassert (! XFLOAT_MARKED_P (XFLOAT (val)));
  bytes_since_gc += sizeof (struct Lisp_Float);
  floats_consed++;
  return val;
}

#define CONS_BLOCK(fptr) \
  (eassert (! pdumper_object_p (fptr)),                                  \
   ((struct cons_block *) ((uintptr_t) (fptr) & ~(BLOCK_ALIGN - 1))))

#define CONS_INDEX(fptr) \
  (((uintptr_t) (fptr) & (BLOCK_ALIGN - 1)) / sizeof (struct Lisp_Cons))

struct cons_block
{
  /* Data first, to preserve alignment.  */
  struct Lisp_Cons conses[BLOCK_NCONS];
  bits_word gcmarkbits[1 + BLOCK_NCONS / BITS_PER_BITS_WORD];
  struct cons_block *next;
};

#define XCONS_MARKED_P(fptr) \
  GETMARKBIT (CONS_BLOCK (fptr), CONS_INDEX ((fptr)))

#define XMARK_CONS(fptr) \
  SETMARKBIT (CONS_BLOCK (fptr), CONS_INDEX ((fptr)))

#define XUNMARK_CONS(fptr) \
  UNSETMARKBIT (CONS_BLOCK (fptr), CONS_INDEX ((fptr)))

static struct cons_block *cons_block;
static int cons_block_index = BLOCK_NCONS;
static struct Lisp_Cons *cons_free_list;

/* Explicitly free a cons cell by putting it on the free list.  */

void
free_cons (struct Lisp_Cons *ptr)
{
  ptr->u.s.u.chain = cons_free_list;
  ptr->u.s.car = dead_object ();
  cons_free_list = ptr;
  ptrdiff_t nbytes = sizeof *ptr;
  bytes_since_gc -= nbytes;
}

DEFUN ("cons", Fcons, Scons, 2, 2, 0,
       doc: /* Create a new cons, give it CAR and CDR as components, and return it.  */)
  (Lisp_Object car, Lisp_Object cdr)
{
  register Lisp_Object val;

  if (cons_free_list)
    {
      XSETCONS (val, cons_free_list);
      cons_free_list = cons_free_list->u.s.u.chain;
    }
  else
    {
      if (cons_block_index == BLOCK_NCONS)
	{
	  struct cons_block *new
	    = lisp_align_malloc (sizeof *new, MEM_TYPE_CONS);
	  memset (new->gcmarkbits, 0, sizeof new->gcmarkbits);
	  new->next = cons_block;
	  cons_block = new;
	  cons_block_index = 0;
	}
      XSETCONS (val, &cons_block->conses[cons_block_index]);
      cons_block_index++;
    }

  XSETCAR (val, car);
  XSETCDR (val, cdr);
  eassert (! XCONS_MARKED_P (XCONS (val)));
  bytes_since_gc += sizeof (struct Lisp_Cons);
  cons_cells_consed++;

  return val;
}

/* Make a list of 1, 2, 3, 4 or 5 specified objects.  */

Lisp_Object
list1 (Lisp_Object arg1)
{
  return Fcons (arg1, Qnil);
}

Lisp_Object
list2 (Lisp_Object arg1, Lisp_Object arg2)
{
  return Fcons (arg1, Fcons (arg2, Qnil));
}


Lisp_Object
list3 (Lisp_Object arg1, Lisp_Object arg2, Lisp_Object arg3)
{
  return Fcons (arg1, Fcons (arg2, Fcons (arg3, Qnil)));
}

Lisp_Object
list4 (Lisp_Object arg1, Lisp_Object arg2, Lisp_Object arg3, Lisp_Object arg4)
{
  return Fcons (arg1, Fcons (arg2, Fcons (arg3, Fcons (arg4, Qnil))));
}

Lisp_Object
list5 (Lisp_Object arg1, Lisp_Object arg2, Lisp_Object arg3, Lisp_Object arg4,
       Lisp_Object arg5)
{
  return Fcons (arg1, Fcons (arg2, Fcons (arg3, Fcons (arg4,
						       Fcons (arg5, Qnil)))));
}

/* Make a list of COUNT Lisp_Objects, where ARG is the first one.
   Use CONS to construct the pairs.  AP has any remaining args.  */
static Lisp_Object
cons_listn (ptrdiff_t count, Lisp_Object arg,
	    Lisp_Object (*cons) (Lisp_Object, Lisp_Object), va_list ap)
{
  eassume (0 < count);
  Lisp_Object val = cons (arg, Qnil);
  Lisp_Object tail = val;
  for (ptrdiff_t i = 1; i < count; i++)
    {
      Lisp_Object elem = cons (va_arg (ap, Lisp_Object), Qnil);
      XSETCDR (tail, elem);
      tail = elem;
    }
  return val;
}

/* Make a list of COUNT Lisp_Objects, where ARG1 is the first one.  */
Lisp_Object
listn (ptrdiff_t count, Lisp_Object arg1, ...)
{
  va_list ap;
  va_start (ap, arg1);
  Lisp_Object val = cons_listn (count, arg1, Fcons, ap);
  va_end (ap);
  return val;
}

/* Make a pure list of COUNT Lisp_Objects, where ARG1 is the first one.  */
Lisp_Object
pure_listn (ptrdiff_t count, Lisp_Object arg1, ...)
{
  va_list ap;
  va_start (ap, arg1);
  Lisp_Object val = cons_listn (count, arg1, pure_cons, ap);
  va_end (ap);
  return val;
}

DEFUN ("list", Flist, Slist, 0, MANY, 0,
       doc: /* Return a newly created list with specified arguments as elements.
Allows any number of arguments, including zero.
usage: (list &rest OBJECTS)  */)
  (ptrdiff_t nargs, Lisp_Object *args)
{
  register Lisp_Object val;
  val = Qnil;

  while (nargs > 0)
    {
      nargs--;
      val = Fcons (args[nargs], val);
    }
  return val;
}

DEFUN ("make-list", Fmake_list, Smake_list, 2, 2, 0,
       doc: /* Return a newly created list of length LENGTH, with each element being INIT.  */)
  (Lisp_Object length, Lisp_Object init)
{
  Lisp_Object val = Qnil;
  CHECK_FIXNAT (length);

  for (EMACS_INT size = XFIXNAT (length); 0 < size; size--)
    {
      val = Fcons (init, val);
      rarely_quit (size);
    }

  return val;
}

/* Sometimes a vector's contents are merely a pointer internally used
   in vector allocation code.  On the rare platforms where a null
   pointer cannot be tagged, represent it with a Lisp 0.
   Usually you don't want to touch this.  */

static struct Lisp_Vector *
next_vector (struct Lisp_Vector *v)
{
  return XUNTAG (v->contents[0], Lisp_Int0, struct Lisp_Vector);
}

static void
set_next_vector (struct Lisp_Vector *v, struct Lisp_Vector *p)
{
  v->contents[0] = make_lisp_ptr (p, Lisp_Int0);
}

/* Advance vector pointer over a block data.  */

static struct Lisp_Vector *
ADVANCE (struct Lisp_Vector *v, ptrdiff_t nbytes)
{
  void *vv = v;
  char *cv = vv;
  void *p = cv + nbytes;
  return p;
}

static ptrdiff_t
VINDEX (ptrdiff_t nbytes)
{
  eassume (LISP_VECTOR_MIN <= nbytes);
  return (nbytes - LISP_VECTOR_MIN) / word_size;
}

/* So-called large vectors are managed outside vector blocks.

   As C99 does not allow one struct to hold a
   flexible-array-containing struct such as Lisp_Vector, we append the
   Lisp_Vector to the large_vector in memory, and retrieve it via
   large_vector_contents().
*/

struct large_vector
{
  struct large_vector *next;
};

enum
  {
    large_vector_contents_offset = ROUNDUP (sizeof (struct large_vector), LISP_ALIGNMENT)
  };

static struct Lisp_Vector *
large_vector_contents (struct large_vector *p)
{
  return (struct Lisp_Vector *) ((char *) p + large_vector_contents_offset);
}

/* This internal type is used to maintain an underlying storage
   for small vectors.  */

struct vector_block
{
  char data[VBLOCK_NBYTES];
  struct vector_block *next;
};

/* Chain of vector blocks.  */

static struct vector_block *vector_blocks;

/* Each IDX points to a chain of vectors of word-length IDX+1.  */

static struct Lisp_Vector *vector_free_lists[VBLOCK_NFREE_LISTS];

/* Singly-linked list of large vectors.  */

static struct large_vector *large_vectors;

/* The only vector with 0 slots, allocated from pure space.  */

Lisp_Object zero_vector;

static void
add_vector_free_lists (struct Lisp_Vector *v, ptrdiff_t nbytes)
{
  eassume (header_size <= nbytes);
  ptrdiff_t nwords = (nbytes - header_size) / word_size;
  XSETPVECTYPESIZE (v, PVEC_FREE, 0, nwords);
  eassert (nbytes % word_size == 0);
  ptrdiff_t vindex = VINDEX (nbytes);
  eassert (vindex < VBLOCK_NFREE_LISTS);
  set_next_vector (v, vector_free_lists[vindex]);
  vector_free_lists[vindex] = v;
}

static struct vector_block *
allocate_vector_block (void)
{
  struct vector_block *block = xmalloc (sizeof *block);

#ifndef GC_MALLOC_CHECK
  mem_insert (block->data, block->data + VBLOCK_NBYTES,
	      MEM_TYPE_VBLOCK);
#endif

  block->next = vector_blocks;
  vector_blocks = block;
  return block;
}

static void
init_vectors (void)
{
  zero_vector = make_pure_vector (0);
  staticpro (&zero_vector);
}

/* Nonzero if VECTOR pointer is valid pointer inside BLOCK.  */

#define VECTOR_IN_BLOCK(vector, block)		\
  ((char *) (vector) <= (block)->data		\
   + VBLOCK_NBYTES - LISP_VECTOR_MIN)

/* Return nbytes of vector with HDR.  */

ptrdiff_t
vectorlike_nbytes (const union vectorlike_header *hdr)
{
  ptrdiff_t size = hdr->size & ~ARRAY_MARK_FLAG;
  ptrdiff_t nwords;

  if (size & PSEUDOVECTOR_FLAG)
    {
      if (PSEUDOVECTOR_TYPEP (hdr, PVEC_BOOL_VECTOR))
        {
          struct Lisp_Bool_Vector *bv = (struct Lisp_Bool_Vector *) hdr;
	  ptrdiff_t word_bytes = (bool_vector_words (bv->size)
				  * sizeof (bits_word));
	  ptrdiff_t boolvec_bytes = bool_header_size + word_bytes;
	  verify (header_size <= bool_header_size);
	  nwords = (boolvec_bytes - header_size + word_size - 1) / word_size;
        }
      else
	nwords = ((size & PSEUDOVECTOR_SIZE_MASK)
		  + ((size & PSEUDOVECTOR_REST_MASK)
		     >> PSEUDOVECTOR_SIZE_BITS));
    }
  else
    nwords = size;
  return header_size + word_size * nwords;
}

/* Convert a pseudovector pointer P to its underlying struct T pointer.
   Verify that the struct is small, since free_by_pvtype() is called
   only on small vector-like objects.  */

#define PSEUDOVEC_STRUCT(p, t) \
  verify_expr ((header_size + VECSIZE (struct t) * word_size \
		<= LARGE_VECTOR_THRESH), \
	       (struct t *) (p))

/* Release extra resources still in use by VECTOR, which may be any
   small vector-like object.  */

static void
free_by_pvtype (struct Lisp_Vector *vector)
{
  detect_suspicious_free (vector);

  if (PSEUDOVECTOR_TYPEP (&vector->header, PVEC_BIGNUM))
    mpz_clear (PSEUDOVEC_STRUCT (vector, Lisp_Bignum)->value);
  else if (PSEUDOVECTOR_TYPEP (&vector->header, PVEC_FINALIZER))
    unchain_finalizer (PSEUDOVEC_STRUCT (vector, Lisp_Finalizer));
  else if (PSEUDOVECTOR_TYPEP (&vector->header, PVEC_FONT))
    {
      if ((vector->header.size & PSEUDOVECTOR_SIZE_MASK) == FONT_OBJECT_MAX)
	{
	  struct font *font = PSEUDOVEC_STRUCT (vector, font);
	  struct font_driver const *drv = font->driver;

	  /* The font driver might sometimes be NULL, e.g. if Emacs was
	     interrupted before it had time to set it up.  */
	  if (drv)
	    {
	      /* Attempt to catch subtle bugs like Bug#16140.  */
	      eassert (valid_font_driver (drv));
	      drv->close_font (font);
	    }
	}
    }
  else if (PSEUDOVECTOR_TYPEP (&vector->header, PVEC_THREAD))
    finalize_one_thread (PSEUDOVEC_STRUCT (vector, thread_state));
  else if (PSEUDOVECTOR_TYPEP (&vector->header, PVEC_MUTEX))
    finalize_one_mutex (PSEUDOVEC_STRUCT (vector, Lisp_Mutex));
  else if (PSEUDOVECTOR_TYPEP (&vector->header, PVEC_CONDVAR))
    finalize_one_condvar (PSEUDOVEC_STRUCT (vector, Lisp_CondVar));
  else if (PSEUDOVECTOR_TYPEP (&vector->header, PVEC_MARKER))
    {
      /* sweep_buffer should already have unchained this from its buffer.  */
      eassert (! PSEUDOVEC_STRUCT (vector, Lisp_Marker)->buffer);
    }
  else if (PSEUDOVECTOR_TYPEP (&vector->header, PVEC_USER_PTR))
    {
      struct Lisp_User_Ptr *uptr = PSEUDOVEC_STRUCT (vector, Lisp_User_Ptr);
      if (uptr->finalizer)
	uptr->finalizer (uptr->p);
    }
#ifdef HAVE_MODULES
  else if (PSEUDOVECTOR_TYPEP (&vector->header, PVEC_MODULE_FUNCTION))
    {
      ATTRIBUTE_MAY_ALIAS struct Lisp_Module_Function *function
        = (struct Lisp_Module_Function *) vector;
      module_finalize_function (function);
    }
#endif
#ifdef HAVE_NATIVE_COMP
  else if (PSEUDOVECTOR_TYPEP (&vector->header, PVEC_NATIVE_COMP_UNIT))
    {
      struct Lisp_Native_Comp_Unit *cu =
	PSEUDOVEC_STRUCT (vector, Lisp_Native_Comp_Unit);
      unload_comp_unit (cu);
    }
  else if (PSEUDOVECTOR_TYPEP (&vector->header, PVEC_SUBR))
    {
      struct Lisp_Subr *subr =
	PSEUDOVEC_STRUCT (vector, Lisp_Subr);
      if (! NILP (subr->native_comp_u))
	{
	  /* FIXME Alternative and non invasive solution to this
	     cast?  */
	  xfree ((char *)subr->symbol_name);
	  xfree (subr->native_c_name);
	}
    }
#endif
#ifdef HAVE_TREE_SITTER
  else if (PSEUDOVECTOR_TYPEP (&vector->header, PVEC_TREE_SITTER))
    {
      struct Lisp_Tree_Sitter *lisp_parser
	= PSEUDOVEC_STRUCT (vector, Lisp_Tree_Sitter);
      if (lisp_parser->highlight_names != NULL)
	xfree (lisp_parser->highlight_names);
      if (lisp_parser->highlights_query != NULL)
	xfree (lisp_parser->highlights_query);
      if (lisp_parser->highlighter != NULL)
	ts_highlighter_delete (lisp_parser->highlighter);
      if (lisp_parser->tree != NULL)
	ts_tree_delete(lisp_parser->tree);
      if (lisp_parser->prev_tree != NULL)
	ts_tree_delete(lisp_parser->prev_tree);
      if (lisp_parser->parser != NULL)
	ts_parser_delete(lisp_parser->parser);
    }
  else if (PSEUDOVECTOR_TYPEP (&vector->header, PVEC_TREE_SITTER_NODE))
    {
    }
#endif
#ifdef HAVE_SQLITE3
  else if (PSEUDOVECTOR_TYPEP (&vector->header, PVEC_SQLITE))
    {
      /* clean s___ up.  To be implemented.  */
    }
#endif
}

/* Reclaim space used by unmarked vectors.  */

static void
sweep_vectors (void)
{
  memset (vector_free_lists, 0, sizeof (vector_free_lists));

  gcstat.total_vectors =
    gcstat.total_vector_slots =
    gcstat.total_free_vector_slots = 0;

  /* Non-large vectors in VECTOR_BLOCKS.  */
  for (struct vector_block *block = vector_blocks,
	 **bprev = &vector_blocks;
       block != NULL;
       block = *bprev)
    {
      ptrdiff_t run_bytes = 0;
      struct Lisp_Vector *run_vector = NULL;
      for (struct Lisp_Vector *vector = (struct Lisp_Vector *) block->data;
	   VECTOR_IN_BLOCK (vector, block);
	   (void) vector)
	{
	  ptrdiff_t nbytes = vector_nbytes (vector);
	  if (vector_marked_p (vector))
	    {
	      if (run_vector)
		{
		  eassume (run_bytes && run_bytes % word_size == 0);
		  add_vector_free_lists (run_vector, run_bytes);
		  gcstat.total_free_vector_slots += run_bytes / word_size;
		  run_bytes = 0;
		  run_vector = NULL;
		}
	      XUNMARK_VECTOR (vector);
	      gcstat.total_vectors++;
	      gcstat.total_vector_slots += nbytes / word_size;
	    }
	  else
	    {
	      free_by_pvtype (vector);
	      if (run_vector == NULL)
		{
		  eassert (run_bytes == 0);
		  run_vector = vector;
		}
	      run_bytes += nbytes;
	    }
	  vector = ADVANCE (vector, nbytes);
	}

      if (run_vector == (struct Lisp_Vector *) block->data)
	{
	  /* If RUN_VECTOR never wavered from its initial
	     assignment, then nothing in the block was marked.
	     Harvest it back to OS.  */
	  *bprev = block->next;
#ifndef GC_MALLOC_CHECK
	  mem_delete (mem_find (block->data));
#endif
	  xfree (block);
	}
      else
	{
	  bprev = &block->next;
	  if (run_vector)
	    {
	      /* block ended in an unmarked vector */
	      add_vector_free_lists (run_vector, run_bytes);
	      gcstat.total_free_vector_slots += run_bytes / word_size;
	    }
	}
    }

  /* Free floating large vectors.  */
  for (struct large_vector *lv = large_vectors,
	 **lvprev = &large_vectors;
       lv != NULL;
       lv = *lvprev)
    {
      struct Lisp_Vector *vector = large_vector_contents (lv);
      if (XVECTOR_MARKED_P (vector))
	{
	  XUNMARK_VECTOR (vector);
	  gcstat.total_vectors++;
	  gcstat.total_vector_slots
	    += (vector->header.size & PSEUDOVECTOR_FLAG
		? vector_nbytes (vector) / word_size
		: header_size / word_size + vector->header.size);
	  lvprev = &lv->next;
	}
      else
	{
	  *lvprev = lv->next;
	  lisp_free (lv);
	}
    }
}

/* Maximum number of elements in a vector.  This is a macro so that it
   can be used in an integer constant expression.  */

#define VECTOR_ELTS_MAX \
  ((ptrdiff_t) \
   min (((min (PTRDIFF_MAX, SIZE_MAX) - header_size - large_vector_contents_offset) \
	 / word_size), \
	MOST_POSITIVE_FIXNUM))

/* Return a newly allocated Lisp_Vector.

   For whatever reason, LEN words consuming more than half VBLOCK_NBYTES
   is considered "large."
  */

struct Lisp_Vector *
allocate_vectorlike (ptrdiff_t len, bool q_clear)
{
  ptrdiff_t nbytes = header_size + len * word_size;
  struct Lisp_Vector *p = NULL;

  if (len == 0)
    return XVECTOR (zero_vector);

  if (len > VECTOR_ELTS_MAX)
    memory_full (SIZE_MAX);

  if (nbytes > LARGE_VECTOR_THRESH)
    {
      struct large_vector *lv = lisp_malloc (large_vector_contents_offset + nbytes,
					     q_clear, MEM_TYPE_VECTORLIKE);
      lv->next = large_vectors;
      large_vectors = lv;
      p = large_vector_contents (lv);
    }
  else
    {
      ptrdiff_t restbytes = 0;

      eassume (LISP_VECTOR_MIN <= nbytes && nbytes <= LARGE_VECTOR_THRESH);
      eassume (nbytes % word_size == 0);

      for (ptrdiff_t exact = VINDEX (nbytes), index = exact;
	   index < VBLOCK_NFREE_LISTS; ++index)
	{
	  restbytes = index * word_size + LISP_VECTOR_MIN - nbytes;
	  eassert (restbytes || index == exact);
	  /* Either leave no residual or one big enough to sustain a
	     non-degenerate vector.  A hanging chad of MEM_TYPE_VBLOCK
	     triggers all manner of GC_MALLOC_CHECK failures.  */
	  if (! restbytes || restbytes >= LISP_VECTOR_MIN)
	    if (vector_free_lists[index])
	      {
		p = vector_free_lists[index];
		vector_free_lists[index] = next_vector (p);
		break;
	      }
	}

      if (! p)
	{
	  /* Need new block */
	  p = (struct Lisp_Vector *) allocate_vector_block ()->data;
	  restbytes = VBLOCK_NBYTES - nbytes;
	}

      if (restbytes)
	{
	  /* Tack onto free list corresponding to VINDEX(RESTBYTES).  */
	  eassert (restbytes % word_size == 0);
	  eassert (restbytes >= LISP_VECTOR_MIN);
	  add_vector_free_lists (ADVANCE (p, nbytes), restbytes);
	}

      if (q_clear)
	memclear (p, nbytes);
    }

  if (find_suspicious_object_in_range (p, (char *) p + nbytes))
    emacs_abort ();

  bytes_since_gc += nbytes;
  vector_cells_consed += len;

  p->header.size = len;
  return p;
}

struct Lisp_Vector *
allocate_pseudovector (int memlen, int lisplen,
		       int zerolen, enum pvec_type tag)
{
  /* Catch bogus values.  */
  enum { size_max = (1 << PSEUDOVECTOR_SIZE_BITS) - 1 };
  enum { rest_max = (1 << PSEUDOVECTOR_REST_BITS) - 1 };
  verify (size_max + rest_max <= VECTOR_ELTS_MAX);
  eassert (0 <= tag && tag <= PVEC_FONT);
  eassert (0 <= lisplen && lisplen <= zerolen && zerolen <= memlen);
  eassert (lisplen <= size_max);
  eassert (memlen <= size_max + rest_max);

  struct Lisp_Vector *v = allocate_vectorlike (memlen, false);
  /* Only the first LISPLEN slots will be traced normally by the GC.  */
  memclear (v->contents, zerolen * word_size);
  XSETPVECTYPESIZE (v, tag, lisplen, memlen - lisplen);
  return v;
}

struct buffer *
allocate_buffer (void)
{
  struct buffer *b
    = ALLOCATE_PSEUDOVECTOR (struct buffer, cursor_in_non_selected_windows_,
			     PVEC_BUFFER);
  BUFFER_PVEC_INIT (b);
  /* Note that the rest fields of B are not initialized.  */
  return b;
}

/* Allocate a record with COUNT slots.  COUNT must be positive, and
   includes the type slot.  */

static struct Lisp_Vector *
allocate_record (EMACS_INT count)
{
  if (count > PSEUDOVECTOR_SIZE_MASK)
    error ("Attempt to allocate a record of %"pI"d slots; max is %d",
	   count, PSEUDOVECTOR_SIZE_MASK);
  struct Lisp_Vector *p = allocate_vectorlike (count, false);
  p->header.size = count;
  XSETPVECTYPE (p, PVEC_RECORD);
  return p;
}


DEFUN ("make-record", Fmake_record, Smake_record, 3, 3, 0,
       doc: /* Create a new record.
TYPE is its type as returned by `type-of'; it should be either a
symbol or a type descriptor.  SLOTS is the number of non-type slots,
each initialized to INIT.  */)
  (Lisp_Object type, Lisp_Object slots, Lisp_Object init)
{
  CHECK_FIXNAT (slots);
  EMACS_INT size = XFIXNAT (slots) + 1;
  struct Lisp_Vector *p = allocate_record (size);
  p->contents[0] = type;
  for (ptrdiff_t i = 1; i < size; i++)
    p->contents[i] = init;
  return make_lisp_ptr (p, Lisp_Vectorlike);
}

DEFUN ("record", Frecord, Srecord, 1, MANY, 0,
       doc: /* Create a new record.
TYPE is its type as returned by `type-of'; it should be either a
symbol or a type descriptor.  SLOTS is used to initialize the record
slots with shallow copies of the arguments.
usage: (record TYPE &rest SLOTS) */)
  (ptrdiff_t nargs, Lisp_Object *args)
{
  struct Lisp_Vector *p = allocate_record (nargs);
  memcpy (p->contents, args, nargs * sizeof *args);
  return make_lisp_ptr (p, Lisp_Vectorlike);
}

DEFUN ("make-vector", Fmake_vector, Smake_vector, 2, 2, 0,
       doc: /* Return a newly created vector of length LENGTH, with each element being INIT.
See also the function `vector'.  */)
  (Lisp_Object length, Lisp_Object init)
{
  CHECK_TYPE (FIXNATP (length) && XFIXNAT (length) <= PTRDIFF_MAX,
	      Qwholenump, length);
  return make_vector (XFIXNAT (length), init);
}

/* Return a new vector of length LENGTH with each element being INIT.  */

Lisp_Object
make_vector (ptrdiff_t length, Lisp_Object init)
{
  bool q_clear = NIL_IS_ZERO && NILP (init);
  struct Lisp_Vector *p = allocate_vectorlike (length, q_clear);
  if (! q_clear)
    for (ptrdiff_t i = 0; i < length; i++)
      p->contents[i] = init;
  return make_lisp_ptr (p, Lisp_Vectorlike);
}

DEFUN ("vector", Fvector, Svector, 0, MANY, 0,
       doc: /* Return a newly created vector with specified arguments as elements.
Allows any number of arguments, including zero.
usage: (vector &rest OBJECTS)  */)
  (ptrdiff_t nargs, Lisp_Object *args)
{
  Lisp_Object val = make_uninit_vector (nargs);
  struct Lisp_Vector *p = XVECTOR (val);
  memcpy (p->contents, args, nargs * sizeof *args);
  return val;
}

DEFUN ("make-byte-code", Fmake_byte_code, Smake_byte_code, 4, MANY, 0,
       doc: /* Create a byte-code object with specified arguments as elements.
The arguments should be the ARGLIST, bytecode-string BYTE-CODE, constant
vector CONSTANTS, maximum stack size DEPTH, (optional) DOCSTRING,
and (optional) INTERACTIVE-SPEC.
The first four arguments are required; at most six have any
significance.
The ARGLIST can be either like the one of `lambda', in which case the arguments
will be dynamically bound before executing the byte code, or it can be an
integer of the form NNNNNNNRMMMMMMM where the 7bit MMMMMMM specifies the
minimum number of arguments, the 7-bit NNNNNNN specifies the maximum number
of arguments (ignoring &rest) and the R bit specifies whether there is a &rest
argument to catch the left-over arguments.  If such an integer is used, the
arguments will not be dynamically bound but will be instead pushed on the
stack before executing the byte-code.
usage: (make-byte-code ARGLIST BYTE-CODE CONSTANTS DEPTH &optional DOCSTRING INTERACTIVE-SPEC &rest ELEMENTS)  */)
  (ptrdiff_t nargs, Lisp_Object *args)
{
  if (! ((FIXNUMP (args[COMPILED_ARGLIST])
	  || CONSP (args[COMPILED_ARGLIST])
	  || NILP (args[COMPILED_ARGLIST]))
	 && STRINGP (args[COMPILED_BYTECODE])
	 && !STRING_MULTIBYTE (args[COMPILED_BYTECODE])
	 && VECTORP (args[COMPILED_CONSTANTS])
	 && FIXNATP (args[COMPILED_STACK_DEPTH])))
    error ("Invalid byte-code object");

  pin_string (args[COMPILED_BYTECODE]);  // Bytecode must be immovable.

  /* We used to purecopy everything here, if loadup-pure-table was set.  This worked
     OK for Emacs-23, but with Emacs-24's lexical binding code, it can be
     dangerous, since make-byte-code is used during execution to build
     closures, so any closure built during the preload phase would end up
     copied into pure space, including its free variables, which is sometimes
     just wasteful and other times plainly wrong (e.g. those free vars may want
     to be setcar'd).  */
  Lisp_Object val = Fvector (nargs, args);
  XSETPVECTYPE (XVECTOR (val), PVEC_COMPILED);
  return val;
}

DEFUN ("make-closure", Fmake_closure, Smake_closure, 1, MANY, 0,
       doc: /* Create a byte-code closure from PROTOTYPE and CLOSURE-VARS.
Return a copy of PROTOTYPE, a byte-code object, with CLOSURE-VARS
replacing the elements in the beginning of the constant-vector.
usage: (make-closure PROTOTYPE &rest CLOSURE-VARS) */)
  (ptrdiff_t nargs, Lisp_Object *args)
{
  Lisp_Object protofun = args[0];
  CHECK_TYPE (COMPILEDP (protofun), Qbyte_code_function_p, protofun);

  /* Create a copy of the constant vector, filling it with the closure
     variables in the beginning.  (The overwritten part should just
     contain placeholder values.) */
  Lisp_Object proto_constvec = AREF (protofun, COMPILED_CONSTANTS);
  ptrdiff_t constsize = ASIZE (proto_constvec);
  ptrdiff_t nvars = nargs - 1;
  if (nvars > constsize)
    error ("Closure vars do not fit in constvec");
  Lisp_Object constvec = make_uninit_vector (constsize);
  memcpy (XVECTOR (constvec)->contents, args + 1, nvars * word_size);
  memcpy (XVECTOR (constvec)->contents + nvars,
	  XVECTOR (proto_constvec)->contents + nvars,
	  (constsize - nvars) * word_size);

  /* Return a copy of the prototype function with the new constant vector. */
  ptrdiff_t protosize = PVSIZE (protofun);
  struct Lisp_Vector *v = allocate_vectorlike (protosize, false);
  v->header = XVECTOR (protofun)->header;
  memcpy (v->contents, XVECTOR (protofun)->contents, protosize * word_size);
  v->contents[COMPILED_CONSTANTS] = constvec;
  return make_lisp_ptr (v, Lisp_Vectorlike);
}

struct symbol_block
{
  /* Data first, to preserve alignment.  */
  struct Lisp_Symbol symbols[BLOCK_NSYMBOLS];
  struct symbol_block *next;
};

/* Current symbol block and index of first unused Lisp_Symbol
   structure in it.  */

static struct symbol_block *symbol_block;
static int symbol_block_index = BLOCK_NSYMBOLS;
/* Pointer to the first symbol_block that contains pinned symbols.
   Tests for 24.4 showed that at dump-time, Emacs contains about 15K symbols,
   10K of which are pinned (and all but 250 of them are interned in obarray),
   whereas a "typical session" has in the order of 30K symbols.
   symbol_block_pinned lets mark_pinned_symbols scan only 15K symbols rather
   than 30K to find the 10K symbols we need to mark.  */
static struct symbol_block *symbol_block_pinned;
static struct Lisp_Symbol *symbol_free_list;

static void
set_symbol_name (Lisp_Object sym, Lisp_Object name)
{
  XSYMBOL (sym)->u.s.name = name;
}

void
init_symbol (Lisp_Object val, Lisp_Object name)
{
  struct Lisp_Symbol *p = XSYMBOL (val);
  set_symbol_name (val, name);
  set_symbol_plist (val, Qnil);
  p->u.s.redirect = SYMBOL_PLAINVAL;
  SET_SYMBOL_VAL (p, Qunbound);
  set_symbol_function (val, Qnil);
  set_symbol_next (val, NULL);
  p->u.s.gcmarkbit = false;
  p->u.s.interned = SYMBOL_UNINTERNED;
  p->u.s.trapped_write = SYMBOL_UNTRAPPED_WRITE;
  p->u.s.declared_special = false;
  p->u.s.pinned = false;
}

DEFUN ("make-symbol", Fmake_symbol, Smake_symbol, 1, 1, 0,
       doc: /* Return an uninterned, unbound symbol whose name is NAME. */)
  (Lisp_Object name)
{
  Lisp_Object val;

  CHECK_STRING (name);

  if (symbol_free_list)
    {
      XSETSYMBOL (val, symbol_free_list);
      symbol_free_list = symbol_free_list->u.s.next;
    }
  else
    {
      if (symbol_block_index == BLOCK_NSYMBOLS)
	{
	  struct symbol_block *new
	    = lisp_malloc (sizeof *new, false, MEM_TYPE_SYMBOL);
	  new->next = symbol_block;
	  symbol_block = new;
	  symbol_block_index = 0;
	}
      XSETSYMBOL (val, &symbol_block->symbols[symbol_block_index]);
      symbol_block_index++;
    }

  init_symbol (val, name);
  bytes_since_gc += sizeof (struct Lisp_Symbol);
  symbols_consed++;
  return val;
}

Lisp_Object
make_misc_ptr (void *a)
{
  struct Lisp_Misc_Ptr *p = ALLOCATE_PLAIN_PSEUDOVECTOR (struct Lisp_Misc_Ptr,
							 PVEC_MISC_PTR);
  p->pointer = a;
  return make_lisp_ptr (p, Lisp_Vectorlike);
}

/* Return a new overlay with specified START, END and PLIST.  */

Lisp_Object
build_overlay (Lisp_Object start, Lisp_Object end, Lisp_Object plist)
{
  struct Lisp_Overlay *p = ALLOCATE_PSEUDOVECTOR (struct Lisp_Overlay, plist,
						  PVEC_OVERLAY);
  Lisp_Object overlay = make_lisp_ptr (p, Lisp_Vectorlike);
  OVERLAY_START (overlay) = start;
  OVERLAY_END (overlay) = end;
  set_overlay_plist (overlay, plist);
  p->next = NULL;
  return overlay;
}

DEFUN ("make-marker", Fmake_marker, Smake_marker, 0, 0, 0,
       doc: /* Return a newly allocated marker which does not point at any place.  */)
  (void)
{
  struct Lisp_Marker *p = ALLOCATE_PLAIN_PSEUDOVECTOR (struct Lisp_Marker,
						       PVEC_MARKER);
  p->buffer = 0;
  p->bytepos = 0;
  p->charpos = 0;
  p->next = NULL;
  p->insertion_type = 0;
  p->need_adjustment = 0;
  return make_lisp_ptr (p, Lisp_Vectorlike);
}

/* Return a newly allocated marker which points into BUF
   at character position CHARPOS and byte position BYTEPOS.  */

Lisp_Object
build_marker (struct buffer *buf, ptrdiff_t charpos, ptrdiff_t bytepos)
{
  /* No dead buffers here.  */
  eassert (BUFFER_LIVE_P (buf));

  /* Every character is at least one byte.  */
  eassert (charpos <= bytepos);

  struct Lisp_Marker *m = ALLOCATE_PLAIN_PSEUDOVECTOR (struct Lisp_Marker,
						       PVEC_MARKER);
  m->buffer = buf;
  m->charpos = charpos;
  m->bytepos = bytepos;
  m->insertion_type = 0;
  m->need_adjustment = 0;
  m->next = BUF_MARKERS (buf);
  BUF_MARKERS (buf) = m;
  return make_lisp_ptr (m, Lisp_Vectorlike);
}


/* Return a newly created vector or string with specified arguments as
   elements.  If all the arguments are characters that can fit
   in a string of events, make a string; otherwise, make a vector.

   Allows any number of arguments, including zero.  */

Lisp_Object
make_event_array (ptrdiff_t nargs, Lisp_Object *args)
{
  ptrdiff_t i;

  for (i = 0; i < nargs; i++)
    /* The things that fit in a string
       are characters that are in 0...127,
       after discarding the meta bit and all the bits above it.  */
    if (!FIXNUMP (args[i])
	|| (XFIXNUM (args[i]) & ~(-CHAR_META)) >= 0200)
      return Fvector (nargs, args);

  /* Since the loop exited, we know that all the things in it are
     characters, so we can make a string.  */
  {
    Lisp_Object result;

    result = Fmake_string (make_fixnum (nargs), make_fixnum (0), Qnil);
    for (i = 0; i < nargs; i++)
      {
	SSET (result, i, XFIXNUM (args[i]));
	/* Move the meta bit to the right place for a string char.  */
	if (XFIXNUM (args[i]) & CHAR_META)
	  SSET (result, i, SREF (result, i) | 0x80);
      }

    return result;
  }
}

#ifdef HAVE_MODULES
/* Create a new module user ptr object.  */
Lisp_Object
make_user_ptr (void (*finalizer) (void *), void *p)
{
  struct Lisp_User_Ptr *uptr
    = ALLOCATE_PLAIN_PSEUDOVECTOR (struct Lisp_User_Ptr, PVEC_USER_PTR);
  uptr->finalizer = finalizer;
  uptr->p = p;
  return make_lisp_ptr (uptr, Lisp_Vectorlike);
}
#endif

static void
init_finalizer_list (struct Lisp_Finalizer *head)
{
  head->prev = head->next = head;
}

/* Insert FINALIZER before ELEMENT.  */

static void
finalizer_insert (struct Lisp_Finalizer *element,
                  struct Lisp_Finalizer *finalizer)
{
  eassert (finalizer->prev == NULL);
  eassert (finalizer->next == NULL);
  finalizer->next = element;
  finalizer->prev = element->prev;
  finalizer->prev->next = finalizer;
  element->prev = finalizer;
}

static void
unchain_finalizer (struct Lisp_Finalizer *finalizer)
{
  if (finalizer->prev != NULL)
    {
      eassert (finalizer->next != NULL);
      finalizer->prev->next = finalizer->next;
      finalizer->next->prev = finalizer->prev;
      finalizer->prev = finalizer->next = NULL;
    }
}

static void
mark_finalizer_list (struct Lisp_Finalizer *head)
{
  for (struct Lisp_Finalizer *finalizer = head->next;
       finalizer != head;
       finalizer = finalizer->next)
    {
      set_vectorlike_marked (&finalizer->header);
      mark_object (finalizer->function);
    }
}

/* Move doomed finalizers to list DEST from list SRC.  A doomed
   finalizer is one that is not GC-reachable and whose
   finalizer->function is non-nil.  */

static void
queue_doomed_finalizers (struct Lisp_Finalizer *dest,
                         struct Lisp_Finalizer *src)
{
  for (struct Lisp_Finalizer *current = src->next,
	 *next = current->next;
       current != src;
       current = next, next = current->next)
    {
      if (! vectorlike_marked_p (&current->header)
          && ! NILP (current->function))
        {
          unchain_finalizer (current);
          finalizer_insert (dest, current);
        }
    }
}

static Lisp_Object
run_finalizer_handler (Lisp_Object args)
{
  add_to_log ("finalizer failed: %S", args);
  return Qnil;
}

static void
run_finalizer_function (Lisp_Object function)
{
  specpdl_ref count = SPECPDL_INDEX ();
#ifdef HAVE_PDUMPER
  ++number_finalizers_run;
#endif

  specbind (Qinhibit_quit, Qt);
  internal_condition_case_1 (call0, function, Qt, run_finalizer_handler);
  unbind_to (count, Qnil);
}

static void
run_finalizers (struct Lisp_Finalizer *finalizers)
{
  struct Lisp_Finalizer *finalizer;
  Lisp_Object function;

  while (finalizers->next != finalizers)
    {
      finalizer = finalizers->next;
      unchain_finalizer (finalizer);
      function = finalizer->function;
      if (! NILP (function))
	{
	  finalizer->function = Qnil;
	  run_finalizer_function (function);
	}
    }
}

DEFUN ("make-finalizer", Fmake_finalizer, Smake_finalizer, 1, 1, 0,
       doc: /* Wrap FUNCTION in a finalizer (similar to destructor).
+FUNCTION is called in an end-run around gc once its finalizer object
+becomes unreachable or only reachable from other finalizers.  */)
  (Lisp_Object function)
{
  CHECK_TYPE (FUNCTIONP (function), Qfunctionp, function);
  struct Lisp_Finalizer *finalizer
    = ALLOCATE_PSEUDOVECTOR (struct Lisp_Finalizer, function, PVEC_FINALIZER);
  finalizer->function = function;
  finalizer->prev = finalizer->next = NULL;
  finalizer_insert (&finalizers, finalizer);
  return make_lisp_ptr (finalizer, Lisp_Vectorlike);
}


/* With the rare exception of functions implementing block-based
   allocation of various types, you should not directly test or set GC
   mark bits on objects.  Some objects might live in special memory
   regions (e.g., a dump image) and might store their mark bits
   elsewhere.  */

static bool
vector_marked_p (const struct Lisp_Vector *v)
{
  if (pdumper_object_p (v))
    {
      /* Look at cold_start first so that we don't have to fault in
         the vector header just to tell that it's a bool vector.  */
      if (pdumper_cold_object_p (v))
        {
          eassert (PSEUDOVECTOR_TYPE (v) == PVEC_BOOL_VECTOR);
          return true;
        }
      return pdumper_marked_p (v);
    }
  return XVECTOR_MARKED_P (v);
}

static void
set_vector_marked (struct Lisp_Vector *v)
{
  if (pdumper_object_p (v))
    {
      eassert (PSEUDOVECTOR_TYPE (v) != PVEC_BOOL_VECTOR);
      pdumper_set_marked (v);
    }
  else
    XMARK_VECTOR (v);
}

static bool
vectorlike_marked_p (const union vectorlike_header *header)
{
  return vector_marked_p ((const struct Lisp_Vector *) header);
}

static void
set_vectorlike_marked (union vectorlike_header *header)
{
  set_vector_marked ((struct Lisp_Vector *) header);
}

static bool
cons_marked_p (const struct Lisp_Cons *c)
{
  return pdumper_object_p (c)
    ? pdumper_marked_p (c)
    : XCONS_MARKED_P (c);
}

static void
set_cons_marked (struct Lisp_Cons *c)
{
  if (pdumper_object_p (c))
    pdumper_set_marked (c);
  else
    XMARK_CONS (c);
}

static bool
string_marked_p (const struct Lisp_String *s)
{
  return pdumper_object_p (s)
    ? pdumper_marked_p (s)
    : XSTRING_MARKED_P (s);
}

static void
set_string_marked (struct Lisp_String *s)
{
  if (pdumper_object_p (s))
    pdumper_set_marked (s);
  else
    XMARK_STRING (s);
}

static bool
symbol_marked_p (const struct Lisp_Symbol *s)
{
  return pdumper_object_p (s)
    ? pdumper_marked_p (s)
    : s->u.s.gcmarkbit;
}

static void
set_symbol_marked (struct Lisp_Symbol *s)
{
  if (pdumper_object_p (s))
    pdumper_set_marked (s);
  else
    s->u.s.gcmarkbit = true;
}

static bool
interval_marked_p (INTERVAL i)
{
  return pdumper_object_p (i)
    ? pdumper_marked_p (i)
    : i->gcmarkbit;
}

static void
set_interval_marked (INTERVAL i)
{
  if (pdumper_object_p (i))
    pdumper_set_marked (i);
  else
    i->gcmarkbit = true;
}

void
memory_full (size_t nbytes)
{
  const size_t enough = (1 << 14);

  if (! initialized)
    fatal ("memory exhausted");

  Vmemory_full = Qt;
  if (nbytes > enough)
    {
      void *p = malloc (enough);
      if (p)
	{
	  Vmemory_full = Qnil;
	  free (p);
	}
    }

  xsignal (Qnil, Vmemory_signal_data);
}

static void
mem_init (void)
{
  mem_z.left = mem_z.right = MEM_NIL;
  mem_z.parent = NULL;
  mem_z.color = MEM_BLACK;
  mem_z.start = mem_z.end = NULL;
  mem_root = MEM_NIL;
}

/* Return mem_node containing START or failing that, MEM_NIL.  */

struct mem_node *
mem_find (void *start)
{
  struct mem_node *p;

  if (start < min_heap_address || start > max_heap_address)
    return MEM_NIL;

  /* Make the search always successful to speed up the loop below.  */
  mem_z.start = start;
  mem_z.end = (char *) start + 1;

  p = mem_root;
  while (start < p->start || start >= p->end)
    p = start < p->start ? p->left : p->right;
  return p;
}


/* Insert node representing mem block of TYPE spanning START and END.
   Return the inserted node.  */

static struct mem_node *
mem_insert (void *start, void *end, enum mem_type type)
{
  struct mem_node *c, *parent, *x;

  if (min_heap_address == NULL || start < min_heap_address)
    min_heap_address = start;
  if (max_heap_address == NULL || end > max_heap_address)
    max_heap_address = end;

  /* See where in the tree a node for START belongs.  In this
     particular application, it shouldn't happen that a node is already
     present.  For debugging purposes, let's check that.  */
  c = mem_root;
  parent = NULL;

  while (c != MEM_NIL)
    {
      parent = c;
      c = start < c->start ? c->left : c->right;
    }

  /* Create a new node.  */
#ifdef GC_MALLOC_CHECK
  x = malloc (sizeof *x);
  if (x == NULL)
    emacs_abort ();
#else
  x = xmalloc (sizeof *x);
#endif
  x->start = start;
  x->end = end;
  x->type = type;
  x->parent = parent;
  x->left = x->right = MEM_NIL;
  x->color = MEM_RED;

  /* Insert it as child of PARENT or install it as root.  */
  if (parent)
    {
      if (start < parent->start)
	parent->left = x;
      else
	parent->right = x;
    }
  else
    mem_root = x;

  /* Re-establish red-black tree properties.  */
  mem_insert_fixup (x);

  return x;
}


/* Insert node X, then rebalance red-black tree.  X is always red.  */

static void
mem_insert_fixup (struct mem_node *x)
{
  while (x != mem_root && x->parent->color == MEM_RED)
    {
      /* X is red and its parent is red.  This is a violation of
	 red-black tree property #3.  */

      if (x->parent == x->parent->parent->left)
	{
	  /* We're on the left side of our grandparent, and Y is our
	     "uncle".  */
	  struct mem_node *y = x->parent->parent->right;

	  if (y->color == MEM_RED)
	    {
	      /* Uncle and parent are red but should be black because
		 X is red.  Change the colors accordingly and proceed
		 with the grandparent.  */
	      x->parent->color = MEM_BLACK;
	      y->color = MEM_BLACK;
	      x->parent->parent->color = MEM_RED;
	      x = x->parent->parent;
            }
	  else
	    {
	      /* Parent and uncle have different colors; parent is
		 red, uncle is black.  */
	      if (x == x->parent->right)
		{
		  x = x->parent;
		  mem_rotate_left (x);
                }

	      x->parent->color = MEM_BLACK;
	      x->parent->parent->color = MEM_RED;
	      mem_rotate_right (x->parent->parent);
            }
        }
      else
	{
	  /* This is the symmetrical case of above.  */
	  struct mem_node *y = x->parent->parent->left;

	  if (y->color == MEM_RED)
	    {
	      x->parent->color = MEM_BLACK;
	      y->color = MEM_BLACK;
	      x->parent->parent->color = MEM_RED;
	      x = x->parent->parent;
            }
	  else
	    {
	      if (x == x->parent->left)
		{
		  x = x->parent;
		  mem_rotate_right (x);
		}

	      x->parent->color = MEM_BLACK;
	      x->parent->parent->color = MEM_RED;
	      mem_rotate_left (x->parent->parent);
            }
        }
    }

  /* The root may have been changed to red due to the algorithm.  Set
     it to black so that property #5 is satisfied.  */
  mem_root->color = MEM_BLACK;
}


/*   (x)                   (y)
     / \                   / \
    a   (y)      ===>    (x)  c
        / \              / \
       b   c            a   b  */

static void
mem_rotate_left (struct mem_node *x)
{
  struct mem_node *y;

  /* Turn y's left sub-tree into x's right sub-tree.  */
  y = x->right;
  x->right = y->left;
  if (y->left != MEM_NIL)
    y->left->parent = x;

  /* Y's parent was x's parent.  */
  if (y != MEM_NIL)
    y->parent = x->parent;

  /* Get the parent to point to y instead of x.  */
  if (x->parent)
    {
      if (x == x->parent->left)
	x->parent->left = y;
      else
	x->parent->right = y;
    }
  else
    mem_root = y;

  /* Put x on y's left.  */
  y->left = x;
  if (x != MEM_NIL)
    x->parent = y;
}


/*     (x)                (Y)
       / \                / \
     (y)  c      ===>    a  (x)
     / \                    / \
    a   b                  b   c  */

static void
mem_rotate_right (struct mem_node *x)
{
  struct mem_node *y = x->left;

  x->left = y->right;
  if (y->right != MEM_NIL)
    y->right->parent = x;

  if (y != MEM_NIL)
    y->parent = x->parent;
  if (x->parent)
    {
      if (x == x->parent->right)
	x->parent->right = y;
      else
	x->parent->left = y;
    }
  else
    mem_root = y;

  y->right = x;
  if (x != MEM_NIL)
    x->parent = y;
}


static void
mem_delete (struct mem_node *z)
{
  struct mem_node *x, *y;

  if (!z || z == MEM_NIL)
    return;

  if (z->left == MEM_NIL || z->right == MEM_NIL)
    y = z;
  else
    {
      y = z->right;
      while (y->left != MEM_NIL)
	y = y->left;
    }

  if (y->left != MEM_NIL)
    x = y->left;
  else
    x = y->right;

  x->parent = y->parent;
  if (y->parent)
    {
      if (y == y->parent->left)
	y->parent->left = x;
      else
	y->parent->right = x;
    }
  else
    mem_root = x;

  if (y != z)
    {
      z->start = y->start;
      z->end = y->end;
      z->type = y->type;
    }

  if (y->color == MEM_BLACK)
    mem_delete_fixup (x);

#ifdef GC_MALLOC_CHECK
  free (y);
#else
  xfree (y);
#endif
}


/* Delete X, then rebalance red-black tree.  */

static void
mem_delete_fixup (struct mem_node *x)
{
  while (x != mem_root && x->color == MEM_BLACK)
    {
      if (x == x->parent->left)
	{
	  struct mem_node *w = x->parent->right;

	  if (w->color == MEM_RED)
	    {
	      w->color = MEM_BLACK;
	      x->parent->color = MEM_RED;
	      mem_rotate_left (x->parent);
	      w = x->parent->right;
            }

	  if (w->left->color == MEM_BLACK && w->right->color == MEM_BLACK)
	    {
	      w->color = MEM_RED;
	      x = x->parent;
            }
	  else
	    {
	      if (w->right->color == MEM_BLACK)
		{
		  w->left->color = MEM_BLACK;
		  w->color = MEM_RED;
		  mem_rotate_right (w);
		  w = x->parent->right;
                }
	      w->color = x->parent->color;
	      x->parent->color = MEM_BLACK;
	      w->right->color = MEM_BLACK;
	      mem_rotate_left (x->parent);
	      x = mem_root;
            }
        }
      else
	{
	  struct mem_node *w = x->parent->left;

	  if (w->color == MEM_RED)
	    {
	      w->color = MEM_BLACK;
	      x->parent->color = MEM_RED;
	      mem_rotate_right (x->parent);
	      w = x->parent->left;
            }

	  if (w->right->color == MEM_BLACK && w->left->color == MEM_BLACK)
	    {
	      w->color = MEM_RED;
	      x = x->parent;
            }
	  else
	    {
	      if (w->left->color == MEM_BLACK)
		{
		  w->right->color = MEM_BLACK;
		  w->color = MEM_RED;
		  mem_rotate_left (w);
		  w = x->parent->left;
                }

	      w->color = x->parent->color;
	      x->parent->color = MEM_BLACK;
	      w->left->color = MEM_BLACK;
	      mem_rotate_right (x->parent);
	      x = mem_root;
            }
        }
    }

  x->color = MEM_BLACK;
}


/* Return P "made whole" as a Lisp_String if P's mem_block M
   corresponds to a Lisp_String data field.  */

static struct Lisp_String *
live_string_holding (struct mem_node *m, void *p)
{
  eassert (m->type == MEM_TYPE_STRING);
  struct string_block *b = m->start;
  char *cp = p;
  ptrdiff_t offset = cp - (char *) &b->strings[0];

  /* P must point into a Lisp_String structure, and it
     must not be on the free list.  */
  if (0 <= offset && offset < sizeof b->strings)
    {
      ptrdiff_t off = offset % sizeof b->strings[0];
      /* Since compilers can optimize away struct fields, scan all
	 offsets.  See Bug#28213.  */
      if (off == Lisp_String
	  || off == 0
	  || off == offsetof (struct Lisp_String, u.s.size_byte)
	  || off == offsetof (struct Lisp_String, u.s.intervals)
	  || off == offsetof (struct Lisp_String, u.s.data))
	{
	  struct Lisp_String *s = p = cp -= off;
	  if (s->u.s.data)
	    return s;
	}
    }
  return NULL;
}

static bool
live_string_p (struct mem_node *m, void *p)
{
  return live_string_holding (m, p) == p;
}

/* Return P "made whole" as a Lisp_Cons if P's mem_block M
   corresponds to a Lisp_Cons data field.  */

static struct Lisp_Cons *
live_cons_holding (struct mem_node *m, void *p)
{
  eassert (m->type == MEM_TYPE_CONS);
  struct cons_block *b = m->start;
  char *cp = p;
  ptrdiff_t offset = cp - (char *) &b->conses[0];

  /* P must point into a Lisp_Cons, not be
     one of the unused cells in the current cons block,
     and not be on the free list.  */
  if (0 <= offset && offset < sizeof b->conses
      && (b != cons_block
	  || offset / sizeof b->conses[0] < cons_block_index))
    {
      ptrdiff_t off = offset % sizeof b->conses[0];
      if (off == Lisp_Cons
	  || off == 0
	  || off == offsetof (struct Lisp_Cons, u.s.u.cdr))
	{
	  struct Lisp_Cons *s = p = cp -= off;
	  if (! deadp (s->u.s.car))
	    return s;
	}
    }
  return NULL;
}

static bool
live_cons_p (struct mem_node *m, void *p)
{
  return live_cons_holding (m, p) == p;
}


/* Return P "made whole" as a Lisp_Symbol if P's mem_block M
   corresponds to a Lisp_Symbol data field.  */

static struct Lisp_Symbol *
live_symbol_holding (struct mem_node *m, void *p)
{
  eassert (m->type == MEM_TYPE_SYMBOL);
  struct symbol_block *b = m->start;
  char *cp = p;
  ptrdiff_t offset = cp - (char *) &b->symbols[0];

  /* P must point into the Lisp_Symbol, not be
     one of the unused cells in the current symbol block,
     and not be on the free list.  */
  if (0 <= offset && offset < sizeof b->symbols
      && (b != symbol_block
	  || offset / sizeof b->symbols[0] < symbol_block_index))
    {
      ptrdiff_t off = offset % sizeof b->symbols[0];
      if (off == Lisp_Symbol

	  /* Plain '|| off == 0' would run afoul of GCC 10.2
	     -Wlogical-op, as Lisp_Symbol happens to be zero.  */
	  || (Lisp_Symbol != 0 && off == 0)

	  || off == offsetof (struct Lisp_Symbol, u.s.name)
	  || off == offsetof (struct Lisp_Symbol, u.s.val)
	  || off == offsetof (struct Lisp_Symbol, u.s.function)
	  || off == offsetof (struct Lisp_Symbol, u.s.plist)
	  || off == offsetof (struct Lisp_Symbol, u.s.next))
	{
	  struct Lisp_Symbol *s = p = cp -= off;
	  if (! deadp (s->u.s.function))
	    return s;
	}
    }
  return NULL;
}

static bool
live_symbol_p (struct mem_node *m, void *p)
{
  return live_symbol_holding (m, p) == p;
}


/* Return P "made whole" as a Lisp_Float if P's mem_block M
   corresponds to a Lisp_Float data field.  */

static struct Lisp_Float *
live_float_holding (struct mem_node *m, void *p)
{
  eassert (m->type == MEM_TYPE_FLOAT);
  struct float_block *b = m->start;
  char *cp = p;
  ptrdiff_t offset = cp - (char *) &b->floats[0];

  /* P must point to (or be a tagged pointer to) the start of a
     Lisp_Float and not be one of the unused cells in the current
     float block.  */
  if (0 <= offset && offset < sizeof b->floats)
    {
      int off = offset % sizeof b->floats[0];
      if ((off == Lisp_Float || off == 0)
	  && (b != float_block
	      || offset / sizeof b->floats[0] < float_block_index))
	{
	  p = cp - off;
	  return p;
	}
    }
  return NULL;
}

static bool
live_float_p (struct mem_node *m, void *p)
{
  return live_float_holding (m, p) == p;
}

/* Return VECTOR if P points within it, NULL otherwise.  */

static struct Lisp_Vector *
live_vector_pointer (struct Lisp_Vector *vector, void *p)
{
  void *vvector = vector;
  char *cvector = vvector;
  char *cp = p;
  ptrdiff_t offset = cp - cvector;
  return ((offset == Lisp_Vectorlike
	   || offset == 0
	   || (sizeof vector->header <= offset
	       && offset < vector_nbytes (vector)
	       && (! (vector->header.size & PSEUDOVECTOR_FLAG)
		   ? (offsetof (struct Lisp_Vector, contents) <= offset
		      && (((offset - offsetof (struct Lisp_Vector, contents))
			   % word_size)
			  == 0))
		   /* For non-bool-vector pseudovectors, treat any pointer
		      past the header as valid since it's too much of a pain
		      to write special-case code for every pseudovector.  */
		   : (! PSEUDOVECTOR_TYPEP (&vector->header, PVEC_BOOL_VECTOR)
		      || offset == offsetof (struct Lisp_Bool_Vector, size)
		      || (offsetof (struct Lisp_Bool_Vector, data) <= offset
			  && (((offset
				- offsetof (struct Lisp_Bool_Vector, data))
			       % sizeof (bits_word))
			      == 0))))))
	  ? vector : NULL);
}

/* Return M "made whole" as a large Lisp_Vector if P points within it.  */

static struct Lisp_Vector *
live_large_vector_holding (struct mem_node *m, void *p)
{
  eassert (m->type == MEM_TYPE_VECTORLIKE);
  return live_vector_pointer (large_vector_contents (m->start), p);
}

static bool
live_large_vector_p (struct mem_node *m, void *p)
{
  return live_large_vector_holding (m, p) == p;
}

/* Return M "made whole" as a non-large Lisp_Vector if P points within it.  */

static struct Lisp_Vector *
live_small_vector_holding (struct mem_node *m, void *p)
{
  eassert (m->type == MEM_TYPE_VBLOCK);
  struct Lisp_Vector *vp = p;
  struct vector_block *block = m->start;
  struct Lisp_Vector *vector = (struct Lisp_Vector *) block->data;

  /* P is in the block's allocation range.  Scan the block
     up to P and see whether P points to the start of some
     vector which is not on a free list.  FIXME: check whether
     some allocation patterns (probably a lot of short vectors)
     may cause a substantial overhead of this loop.  */
  while (VECTOR_IN_BLOCK (vector, block) && vector <= vp)
    {
      struct Lisp_Vector *next = ADVANCE (vector, vector_nbytes (vector));
      if (vp < next && ! PSEUDOVECTOR_TYPEP (&vector->header, PVEC_FREE))
	return live_vector_pointer (vector, vp);
      vector = next;
    }
  return NULL;
}

static bool
live_small_vector_p (struct mem_node *m, void *p)
{
  return live_small_vector_holding (m, p) == p;
}

/* Mark P if it points to Lisp data.  */

static void
mark_maybe_pointer (void *p, bool symbol_only)
{
  struct mem_node *m;

#if USE_VALGRIND
  VALGRIND_MAKE_MEM_DEFINED (&p, sizeof (p));
#endif

  /* Mark P if it's an identifiable pdumper object, i.e., P falls
     within the dump file address range, and aligns with a reloc
     instance.

     FIXME: This code assumes that every reachable pdumper object
     is addressed either by a pointer to the object start, or by
     the same pointer with an LSB-style tag.  This assumption
     fails if a pdumper object is reachable only via machine
     addresses of non-initial object components.  Although such
     addressing is rare in machine code generated by C compilers
     from Emacs source code, it can occur in some cases.  To fix
     this problem, the pdumper code should grok non-initial
     addresses, as the non-pdumper code does.  */
  if (pdumper_object_p (p))
    {
      uintptr_t mask = VALMASK & UINTPTR_MAX;
      uintptr_t masked_p = (uintptr_t) p & mask;
      void *po = (void *) masked_p;
      char *cp = p;
      char *cpo = po;
      /* Don't use pdumper_object_p_precise here! It doesn't check the
         tag bits. OBJ here might be complete garbage, so we need to
         verify both the pointer and the tag.  */
      int type = pdumper_find_object_type (po);
      if (pdumper_valid_object_type_p (type)
	  && (! USE_LSB_TAG || p == po || cp - cpo == type))
	{
	  if (type == Lisp_Symbol)
	    mark_object (make_lisp_symbol (po));
	  else if (! symbol_only)
	    mark_object (make_lisp_ptr (po, type));
	}
      return;
    }

  m = mem_find (p);
  if (m != MEM_NIL)
    {
      Lisp_Object obj;

      switch (m->type)
	{
	case MEM_TYPE_NON_LISP:
	  /* Nothing to do; not a pointer to Lisp memory.  */
	  return;

	case MEM_TYPE_CONS:
	  {
	    if (symbol_only)
	      return;
	    struct Lisp_Cons *h = live_cons_holding (m, p);
	    if (!h)
	      return;
	    obj = make_lisp_ptr (h, Lisp_Cons);
	  }
	  break;

	case MEM_TYPE_STRING:
	  {
	    if (symbol_only)
	      return;
	    struct Lisp_String *h = live_string_holding (m, p);
	    if (!h)
	      return;
	    obj = make_lisp_ptr (h, Lisp_String);
	  }
	  break;

	case MEM_TYPE_SYMBOL:
	  {
	    struct Lisp_Symbol *h = live_symbol_holding (m, p);
	    if (!h)
	      return;
	    obj = make_lisp_symbol (h);
	  }
	  break;

	case MEM_TYPE_FLOAT:
	  {
	    if (symbol_only)
	      return;
	    struct Lisp_Float *h = live_float_holding (m, p);
	    if (!h)
	      return;
	    obj = make_lisp_ptr (h, Lisp_Float);
	  }
	  break;

	case MEM_TYPE_VECTORLIKE:
	  {
	    if (symbol_only)
	      return;
	    struct Lisp_Vector *h = live_large_vector_holding (m, p);
	    if (!h)
	      return;
	    obj = make_lisp_ptr (h, Lisp_Vectorlike);
	  }
	  break;

	case MEM_TYPE_VBLOCK:
	  {
	    if (symbol_only)
	      return;
	    struct Lisp_Vector *h = live_small_vector_holding (m, p);
	    if (!h)
	      return;
	    obj = make_lisp_ptr (h, Lisp_Vectorlike);
	  }
	  break;

	default:
	  emacs_abort ();
	}

      mark_object (obj);
    }
}


/* Alignment of pointer values.  Use alignof, as it sometimes returns
   a smaller alignment than GCC's __alignof__ and mark_memory might
   miss objects if __alignof__ were used.  */
#define GC_POINTER_ALIGNMENT alignof (void *)

/* Mark live Lisp objects on the C stack.

   There are several system-dependent problems to consider when
   porting this to new architectures:

   Processor Registers

   We have to mark Lisp objects in CPU registers that can hold local
   variables or are used to pass parameters.

   If __builtin_unwind_init is available, it should suffice to save
   registers in flush_stack_call_func().  This presumably is always
   the case for platforms of interest to Commercial Emacs.  We
   preserve the legacy else-branch that calls test_setjmp() to verify
   the sys_jmp_buf saves registers.

   Stack Layout

   Architectures differ in the way their processor stack is organized.
   For example, the stack might look like this

     +----------------+
     |  Lisp_Object   |  size = 4
     +----------------+
     | something else |  size = 2
     +----------------+
     |  Lisp_Object   |  size = 4
     +----------------+
     |	...	      |

   In such a case, not every Lisp_Object will be aligned equally.  To
   find all Lisp_Object on the stack it won't be sufficient to walk
   the stack in steps of 4 bytes.  Instead, two passes will be
   necessary, one starting at the start of the stack, and a second
   pass starting at the start of the stack + 2.  Likewise, if the
   minimal alignment of Lisp_Objects on the stack is 1, four passes
   would be necessary, each one starting with one byte more offset
   from the stack start.  */

void ATTRIBUTE_NO_SANITIZE_ADDRESS
mark_memory (void const *start, void const *end)
{
  char const *pp;

  /* Allow inverted arguments.  */
  if (end < start)
    {
      void const *tem = start;
      start = end;
      end = tem;
    }

  eassert (((uintptr_t) start) % GC_POINTER_ALIGNMENT == 0);

  /* Ours is not a "precise" gc, in which all object references
     are unambiguous and markable.  Here, for example,

       Lisp_Object obj = build_string ("test");
       struct Lisp_String *ptr = XSTRING (obj);
       garbage_collect ();
       fprintf (stderr, "test '%s'\n", ptr->u.s.data);

     the compiler is liable to optimize away OBJ, so our
     "conservative" gc must recognize that PTR references Lisp
     data.  */

  for (pp = start; (void const *) pp < end; pp += GC_POINTER_ALIGNMENT)
    {
      void *p = *(void *const *) pp;
      mark_maybe_pointer (p, false);

      /* Unmask any struct Lisp_Symbol pointer that make_lisp_symbol
	 previously disguised by adding the address of LISPSYM.
	 On a host with 32-bit pointers and 64-bit Lisp_Objects,
	 a Lisp_Object might be split into registers saved into
	 non-adjacent words and P might be the low-order word's value.  */
      intptr_t ip;
      INT_ADD_WRAPV ((intptr_t) p, (intptr_t) lispsym, &ip);
      mark_maybe_pointer ((void *) ip, true);
    }
}

#ifndef HAVE___BUILTIN_UNWIND_INIT

# ifdef GC_SETJMP_WORKS
static void
test_setjmp (void)
{
}
# else

static bool setjmp_tested_p;
static int longjmps_done;

/* Perform a quick check if it looks like setjmp saves registers in a
   jmp_buf.  Print a message to stderr saying so.  When this test
   succeeds, this is _not_ a proof that setjmp is sufficient for
   conservative stack marking.  Only the sources or a disassembly
   can prove that.  */

static void
test_setjmp (void)
{
  if (setjmp_tested_p)
    return;
  setjmp_tested_p = true;
  char buf[10];
  register int x;
  sys_jmp_buf jbuf;

  /* Arrange for X to be put in a register.  */
  sprintf (buf, "1");
  x = strlen (buf);
  x = 2 * x - 1;

  sys_setjmp (jbuf);
  if (longjmps_done == 1)
    {
      /* Gets here after the sys_longjmp().  */
      if (x != 1)
	/* Didn't restore the register before the setjmp!  */
	emacs_abort ();
    }

  ++longjmps_done;
  x = 2;
  if (longjmps_done == 1)
    sys_longjmp (jbuf, 1);
}
# endif /* ! GC_SETJMP_WORKS */
#endif /* ! HAVE___BUILTIN_UNWIND_INIT */

/* The type of an object near the stack top, whose address can be used
   as a stack scan limit.  */
typedef union
{
  /* Make sure stack_top and m_stack_bottom are properly aligned as GC
     expects.  */
  Lisp_Object o;
  void *p;
#ifndef HAVE___BUILTIN_UNWIND_INIT
  sys_jmp_buf j;
  char c;
#endif
} stacktop_sentry;

/* Yield an address close enough to the top of the stack that the
   garbage collector need not scan above it.  Callers should be
   declared NO_INLINE.  */
#ifdef HAVE___BUILTIN_FRAME_ADDRESS
# define NEAR_STACK_TOP(addr) ((void) (addr), __builtin_frame_address (0))
#else
# define NEAR_STACK_TOP(addr) (addr)
#endif

/* Set *P to the address of the top of the stack.  This must be a
   macro, not a function, so that it is executed in the caller's
   environment.  It is not inside a do-while so that its storage
   survives the macro.  Callers should be declared NO_INLINE.  */
#ifdef HAVE___BUILTIN_UNWIND_INIT
# define SET_STACK_TOP_ADDRESS(p)	\
   stacktop_sentry sentry;		\
   *(p) = NEAR_STACK_TOP (&sentry)
#else
# define SET_STACK_TOP_ADDRESS(p)		\
   stacktop_sentry sentry;			\
   test_setjmp ();				\
   sys_setjmp (sentry.j);			\
   *(p) = NEAR_STACK_TOP (&sentry + (stack_bottom < &sentry.c))
#endif
NO_INLINE /* Ensures registers are spilled. (Bug#41357)  */
void
flush_stack_call_func1 (void (*func) (void *arg), void *arg)
{
  void *end;
  struct thread_state *self = current_thread;
  SET_STACK_TOP_ADDRESS (&end);
  self->stack_top = end;
  func (arg);
  eassert (current_thread == self);
}

/* Determine whether it is safe to access memory at address P.  */
static int
valid_pointer_p (void *p)
{
#ifdef WINDOWSNT
  return w32_valid_pointer_p (p, 16);
#else

  if (ADDRESS_SANITIZER)
    return p ? -1 : 0;

  int fd[2];
  static int under_rr_state;

  if (!under_rr_state)
    under_rr_state = getenv ("RUNNING_UNDER_RR") ? -1 : 1;
  if (under_rr_state < 0)
    return under_rr_state;

  /* Obviously, we cannot just access it (we would SEGV trying), so we
     trick the o/s to tell us whether p is a valid pointer.
     Unfortunately, we cannot use NULL_DEVICE here, as emacs_write may
     not validate p in that case.  */

  if (emacs_pipe (fd) == 0)
    {
      bool valid = emacs_write (fd[1], p, 16) == 16;
      emacs_close (fd[1]);
      emacs_close (fd[0]);
      return valid;
    }

  return -1;
#endif
}

/* Return 2 if OBJ is a killed or special buffer object, 1 if OBJ is a
   valid lisp object, 0 if OBJ is NOT a valid lisp object, or -1 if we
   cannot validate OBJ.  This function can be quite slow, and is used
   only in debugging.  */

int
valid_lisp_object_p (Lisp_Object obj)
{
  if (FIXNUMP (obj))
    return 1;

  void *p = XPNTR (obj);
  if (PURE_P (p))
    return 1;

  if (SYMBOLP (obj) && c_symbol_p (p))
    return ((char *) p - (char *) lispsym) % sizeof lispsym[0] == 0;

  if (p == &buffer_slot_defaults || p == &buffer_slot_symbols)
    return 2;

  if (pdumper_object_p (p))
    return pdumper_object_p_precise (p) ? 1 : 0;

  struct mem_node *m = mem_find (p);

  if (m == MEM_NIL)
    {
      int valid = valid_pointer_p (p);
      if (valid <= 0)
	return valid;

      if (SUBRP (obj))
	return 1;

      return 0;
    }

  switch (m->type)
    {
    case MEM_TYPE_NON_LISP:
      return 0;

    case MEM_TYPE_CONS:
      return live_cons_p (m, p);

    case MEM_TYPE_STRING:
      return live_string_p (m, p);

    case MEM_TYPE_SYMBOL:
      return live_symbol_p (m, p);

    case MEM_TYPE_FLOAT:
      return live_float_p (m, p);

    case MEM_TYPE_VECTORLIKE:
      return live_large_vector_p (m, p);

    case MEM_TYPE_VBLOCK:
      return live_small_vector_p (m, p);

    default:
      break;
    }

  return 0;
}

/* Allocate room for SIZE bytes from pure Lisp storage and return a
   pointer to it.  TYPE is the Lisp type for which the memory is
   allocated.  TYPE < 0 means it's not used for a Lisp object,
   and that the result should have an alignment of -TYPE.

   The bytes are initially zero.

   If pure space is exhausted, allocate space from the heap.  This is
   merely an expedient to let Emacs warn that pure space was exhausted
   and that Emacs should be rebuilt with a larger pure space.  */

static void *
pure_alloc (size_t size, int type)
{
  void *result;

 again:
  if (type >= 0)
    {
      /* Allocate space for a Lisp object from the beginning of the free
	 space with taking account of alignment.  */
      result = pointer_align (purebeg + pure_bytes_used_lisp, LISP_ALIGNMENT);
      pure_bytes_used_lisp = ((char *)result - (char *)purebeg) + size;
    }
  else
    {
      /* Allocate space for a non-Lisp object from the end of the free
	 space.  */
      ptrdiff_t unaligned_non_lisp = pure_bytes_used_non_lisp + size;
      char *unaligned = purebeg + pure_size - unaligned_non_lisp;
      int decr = (intptr_t) unaligned & (-1 - type);
      pure_bytes_used_non_lisp = unaligned_non_lisp + decr;
      result = unaligned - decr;
    }
  pure_bytes_used = pure_bytes_used_lisp + pure_bytes_used_non_lisp;

  if (pure_bytes_used <= pure_size)
    return result;

  /* Don't allocate a large amount here,
     because it might get mmap'd and then its address
     might not be usable.  */
  int small_amount = 10000;
  eassert (size <= small_amount - LISP_ALIGNMENT);
  purebeg = xzalloc (small_amount);
  pure_size = small_amount;
  pure_bytes_used_before_overflow += pure_bytes_used - size;
  pure_bytes_used = 0;
  pure_bytes_used_lisp = pure_bytes_used_non_lisp = 0;

  /* Can't GC if pure storage overflowed because we can't determine
     if something is a pure object or not.  */
  gc_inhibited = true;
  goto again;
}

/* Find the byte sequence {DATA[0], ..., DATA[NBYTES-1], '\0'} from
   the non-Lisp data pool of the pure storage, and return its start
   address.  Return NULL if not found.  */

static char *
find_string_data_in_pure (const char *data, ptrdiff_t nbytes)
{
  int i;
  ptrdiff_t skip, bm_skip[256], last_char_skip, infinity, start, start_max;
  const unsigned char *p;
  char *non_lisp_beg;

  if (pure_bytes_used_non_lisp <= nbytes)
    return NULL;

  /* Set up the Boyer-Moore table.  */
  skip = nbytes + 1;
  for (i = 0; i < 256; i++)
    bm_skip[i] = skip;

  p = (const unsigned char *) data;
  while (--skip > 0)
    bm_skip[*p++] = skip;

  last_char_skip = bm_skip['\0'];

  non_lisp_beg = purebeg + pure_size - pure_bytes_used_non_lisp;
  start_max = pure_bytes_used_non_lisp - (nbytes + 1);

  /* See the comments in the function `boyer_moore' (search.c) for the
     use of `infinity'.  */
  infinity = pure_bytes_used_non_lisp + 1;
  bm_skip['\0'] = infinity;

  p = (const unsigned char *) non_lisp_beg + nbytes;
  start = 0;
  do
    {
      /* Check the last character (== '\0').  */
      do
	{
	  start += bm_skip[*(p + start)];
	}
      while (start <= start_max);

      if (start < infinity)
	/* Couldn't find the last character.  */
	return NULL;

      /* No less than `infinity' means we could find the last
	 character at `p[start - infinity]'.  */
      start -= infinity;

      /* Check the remaining characters.  */
      if (memcmp (data, non_lisp_beg + start, nbytes) == 0)
	/* Found.  */
	return non_lisp_beg + start;

      start += last_char_skip;
    }
  while (start <= start_max);

  return NULL;
}


/* Return a string allocated in pure space.  DATA is a buffer holding
   NCHARS characters, and NBYTES bytes of string data.  MULTIBYTE
   means make the result string multibyte.

   Must get an error if pure storage is full, since if it cannot hold
   a large string it may be able to hold conses that point to that
   string; then the string is not protected from gc.  */

Lisp_Object
make_pure_string (const char *data,
		  ptrdiff_t nchars, ptrdiff_t nbytes, bool multibyte)
{
  Lisp_Object string;
  struct Lisp_String *s = pure_alloc (sizeof *s, Lisp_String);
  s->u.s.data = (unsigned char *) find_string_data_in_pure (data, nbytes);
  if (s->u.s.data == NULL)
    {
      s->u.s.data = pure_alloc (nbytes + 1, -1);
      memcpy (s->u.s.data, data, nbytes);
      s->u.s.data[nbytes] = '\0';
    }
  s->u.s.size = nchars;
  s->u.s.size_byte = multibyte ? nbytes : -1;
  s->u.s.intervals = NULL;
  XSETSTRING (string, s);
  return string;
}

/* Return a string allocated in pure space.  Do not
   allocate the string data, just point to DATA.  */

Lisp_Object
make_pure_c_string (const char *data, ptrdiff_t nchars)
{
  Lisp_Object string;
  struct Lisp_String *s = pure_alloc (sizeof *s, Lisp_String);
  s->u.s.size = nchars;
  s->u.s.size_byte = -2;
  s->u.s.data = (unsigned char *) data;
  s->u.s.intervals = NULL;
  XSETSTRING (string, s);
  return string;
}

static Lisp_Object purecopy (Lisp_Object obj);

/* Return a cons allocated from pure space.  Give it pure copies
   of CAR as car and CDR as cdr.  */

Lisp_Object
pure_cons (Lisp_Object car, Lisp_Object cdr)
{
  Lisp_Object new;
  struct Lisp_Cons *p = pure_alloc (sizeof *p, Lisp_Cons);
  XSETCONS (new, p);
  XSETCAR (new, purecopy (car));
  XSETCDR (new, purecopy (cdr));
  return new;
}


/* Value is a float object with value NUM allocated from pure space.  */

static Lisp_Object
make_pure_float (double num)
{
  Lisp_Object new;
  struct Lisp_Float *p = pure_alloc (sizeof *p, Lisp_Float);
  XSETFLOAT (new, p);
  XFLOAT_INIT (new, num);
  return new;
}

/* Value is a bignum object with value VALUE allocated from pure
   space.  */

static Lisp_Object
make_pure_bignum (Lisp_Object value)
{
  mpz_t const *n = xbignum_val (value);
  size_t i, nlimbs = mpz_size (*n);
  size_t nbytes = nlimbs * sizeof (mp_limb_t);
  mp_limb_t *pure_limbs;
  mp_size_t new_size;

  struct Lisp_Bignum *b = pure_alloc (sizeof *b, Lisp_Vectorlike);
  XSETPVECTYPESIZE (b, PVEC_BIGNUM, 0, VECSIZE (struct Lisp_Bignum));

  int limb_alignment = alignof (mp_limb_t);
  pure_limbs = pure_alloc (nbytes, - limb_alignment);
  for (i = 0; i < nlimbs; ++i)
    pure_limbs[i] = mpz_getlimbn (*n, i);

  new_size = nlimbs;
  if (mpz_sgn (*n) < 0)
    new_size = -new_size;

  mpz_roinit_n (b->value, pure_limbs, new_size);

  return make_lisp_ptr (b, Lisp_Vectorlike);
}

/* Return a vector with room for LEN Lisp_Objects allocated from
   pure space.  */

static Lisp_Object
make_pure_vector (ptrdiff_t len)
{
  Lisp_Object new;
  size_t size = header_size + len * word_size;
  struct Lisp_Vector *p = pure_alloc (size, Lisp_Vectorlike);
  XSETVECTOR (new, p);
  XVECTOR (new)->header.size = len;
  return new;
}

/* Copy all contents and parameters of TABLE to a new table allocated
   from pure space, return the purified table.  */
static struct Lisp_Hash_Table *
purecopy_hash_table (struct Lisp_Hash_Table *table)
{
  eassert (NILP (table->weak));
  eassert (table->purecopy);

  struct Lisp_Hash_Table *pure = pure_alloc (sizeof *pure, Lisp_Vectorlike);
  struct hash_table_test pure_test = table->test;

  /* Purecopy the hash table test.  */
  pure_test.name = purecopy (table->test.name);
  pure_test.user_hash_function = purecopy (table->test.user_hash_function);
  pure_test.user_cmp_function = purecopy (table->test.user_cmp_function);

  pure->header = table->header;
  pure->weak = purecopy (Qnil);
  pure->hash = purecopy (table->hash);
  pure->next = purecopy (table->next);
  pure->index = purecopy (table->index);
  pure->count = table->count;
  pure->next_free = table->next_free;
  pure->purecopy = table->purecopy;
  eassert (!pure->mutable);
  pure->rehash_threshold = table->rehash_threshold;
  pure->rehash_size = table->rehash_size;
  pure->key_and_value = purecopy (table->key_and_value);
  pure->test = pure_test;

  return pure;
}

DEFUN ("purecopy", Fpurecopy, Spurecopy, 1, 1, 0,
       doc: /* Make a copy of object OBJ in pure storage.
Recursively copies contents of vectors and cons cells.
Does not copy symbols.  Copies strings without text properties.  */)
  (register Lisp_Object obj)
{
  if (NILP (Vloadup_pure_table))
    return obj;
  else if (MARKERP (obj) || OVERLAYP (obj) || SYMBOLP (obj))
    /* Can't purify those.  */
    return obj;
  else
    return purecopy (obj);
}

/* Pinned objects are marked before every GC cycle.  */
static struct pinned_object
{
  Lisp_Object object;
  struct pinned_object *next;
} *pinned_objects;

static Lisp_Object
purecopy (Lisp_Object obj)
{
  if (FIXNUMP (obj)
      || (! SYMBOLP (obj) && PURE_P (XPNTR (obj)))
      || SUBRP (obj))
    return obj;    /* Already pure.  */

  if (STRINGP (obj) && XSTRING (obj)->u.s.intervals)
    message_with_string ("Dropping text-properties while making string `%s' pure",
			 obj, true);

  if (! NILP (Vloadup_pure_table)) /* Hash consing.  */
    {
      Lisp_Object tmp = Fgethash (obj, Vloadup_pure_table, Qnil);
      if (! NILP (tmp))
	return tmp;
    }

  if (CONSP (obj))
    obj = pure_cons (XCAR (obj), XCDR (obj));
  else if (FLOATP (obj))
    obj = make_pure_float (XFLOAT_DATA (obj));
  else if (STRINGP (obj))
    obj = make_pure_string (SSDATA (obj), SCHARS (obj),
			    SBYTES (obj),
			    STRING_MULTIBYTE (obj));
  else if (HASH_TABLE_P (obj))
    {
      struct Lisp_Hash_Table *table = XHASH_TABLE (obj);
      /* Do not purify hash tables which haven't been defined with
         :purecopy as non-nil or are weak - they aren't guaranteed to
         not change.  */
      if (! NILP (table->weak) || !table->purecopy)
        {
          /* Instead, add the hash table to the list of pinned objects,
             so that it will be marked during GC.  */
          struct pinned_object *o = xmalloc (sizeof *o);
          o->object = obj;
          o->next = pinned_objects;
          pinned_objects = o;
          return obj; /* Don't hash cons it.  */
        }

      struct Lisp_Hash_Table *h = purecopy_hash_table (table);
      XSET_HASH_TABLE (obj, h);
    }
  else if (COMPILEDP (obj) || VECTORP (obj) || RECORDP (obj))
    {
      struct Lisp_Vector *objp = XVECTOR (obj);
      ptrdiff_t nbytes = vector_nbytes (objp);
      struct Lisp_Vector *vec = pure_alloc (nbytes, Lisp_Vectorlike);
      register ptrdiff_t i;
      ptrdiff_t size = ASIZE (obj);
      if (size & PSEUDOVECTOR_FLAG)
	size &= PSEUDOVECTOR_SIZE_MASK;
      memcpy (vec, objp, nbytes);
      for (i = 0; i < size; i++)
	vec->contents[i] = purecopy (vec->contents[i]);
      // Byte code strings must be pinned.
      if (COMPILEDP (obj) && size >= 2 && STRINGP (vec->contents[1])
	  && !STRING_MULTIBYTE (vec->contents[1]))
	pin_string (vec->contents[1]);
      XSETVECTOR (obj, vec);
    }
  else if (SYMBOLP (obj))
    {
      if (! XSYMBOL (obj)->u.s.pinned && ! c_symbol_p (XSYMBOL (obj)))
	{ /* We can't purify them, but they appear in many pure objects.
	     Mark them as `pinned' so we know to mark them at every GC cycle.  */
	  XSYMBOL (obj)->u.s.pinned = true;
	  symbol_block_pinned = symbol_block;
	}
      /* Don't hash-cons it.  */
      return obj;
    }
  else if (BIGNUMP (obj))
    obj = make_pure_bignum (obj);
  else
    {
      AUTO_STRING (fmt, "Don't know how to purify: %S");
      Fsignal (Qerror, list1 (CALLN (Fformat, fmt, obj)));
    }

  if (! NILP (Vloadup_pure_table)) /* Hash consing.  */
    Fputhash (obj, obj, Vloadup_pure_table);

  return obj;
}



/* Put an entry in staticvec, pointing at the variable with address
   VARADDRESS.  */

void
staticpro (Lisp_Object const *varaddress)
{
  for (int i = 0; i < staticidx; i++)
    eassert (staticvec[i] != varaddress);
  if (staticidx >= NSTATICS)
    fatal ("NSTATICS too small; try increasing and recompiling Emacs.");
  staticvec[staticidx++] = varaddress;
}

static void
allow_garbage_collection (void)
{
  gc_inhibited = false;
}

specpdl_ref
inhibit_garbage_collection (void)
{
  specpdl_ref count = SPECPDL_INDEX ();
  record_unwind_protect_void (allow_garbage_collection);
  gc_inhibited = true;
  return count;
}

/* Calculate total bytes of live objects.  */

static size_t
total_bytes_of_live_objects (void)
{
  return gcstat.total_conses * sizeof (struct Lisp_Cons)
    + gcstat.total_symbols * sizeof (struct Lisp_Symbol)
    + gcstat.total_string_bytes
    + gcstat.total_vector_slots * word_size
    + gcstat.total_floats * sizeof (struct Lisp_Float)
    + gcstat.total_intervals * sizeof (struct interval)
    + gcstat.total_strings * sizeof (struct Lisp_String);
}

#ifdef HAVE_WINDOW_SYSTEM

/* Remove unmarked font-spec and font-entity objects from ENTRY, which is
   (DRIVER-TYPE NUM-FRAMES FONT-CACHE-DATA ...), and return changed entry.  */

static Lisp_Object
compact_font_cache_entry (Lisp_Object entry)
{
  Lisp_Object tail, *prev = &entry;

  for (tail = entry; CONSP (tail); tail = XCDR (tail))
    {
      bool drop = 0;
      Lisp_Object obj = XCAR (tail);

      /* Consider OBJ if it is (font-spec . [font-entity font-entity ...]).  */
      if (CONSP (obj) && GC_FONT_SPEC_P (XCAR (obj))
	  && !vectorlike_marked_p (&GC_XFONT_SPEC (XCAR (obj))->header)
	  /* Don't use VECTORP here, as that calls ASIZE, which could
	     hit assertion violation during GC.  */
	  && (VECTORLIKEP (XCDR (obj))
	      && ! (gc_asize (XCDR (obj)) & PSEUDOVECTOR_FLAG)))
	{
	  ptrdiff_t i, size = gc_asize (XCDR (obj));
	  Lisp_Object obj_cdr = XCDR (obj);

	  /* If font-spec is not marked, most likely all font-entities
	     are not marked too.  But we must be sure that nothing is
	     marked within OBJ before we really drop it.  */
	  for (i = 0; i < size; i++)
            {
              Lisp_Object objlist;

              if (vectorlike_marked_p (
                    &GC_XFONT_ENTITY (AREF (obj_cdr, i))->header))
                break;

              objlist = AREF (AREF (obj_cdr, i), FONT_OBJLIST_INDEX);
              for (; CONSP (objlist); objlist = XCDR (objlist))
                {
                  Lisp_Object val = XCAR (objlist);
                  struct font *font = GC_XFONT_OBJECT (val);

                  if (! NILP (AREF (val, FONT_TYPE_INDEX))
                      && vectorlike_marked_p (&font->header))
                    break;
                }
              if (CONSP (objlist))
		{
		  /* Found a marked font, bail out.  */
		  break;
		}
            }

	  if (i == size)
	    {
	      /* No marked fonts were found, so this entire font
		 entity can be dropped.  */
	      drop = 1;
	    }
	}
      if (drop)
	*prev = XCDR (tail);
      else
	prev = xcdr_addr (tail);
    }
  return entry;
}

/* Compact font caches on all terminals and mark
   everything which is still here after compaction.  */

static void
compact_font_caches (void)
{
  struct terminal *t;

  for (t = terminal_list; t; t = t->next_terminal)
    {
      Lisp_Object cache = TERMINAL_FONT_CACHE (t);
      /* Inhibit compacting the caches if the user so wishes.  Some of
	 the users don't mind a larger memory footprint, but do mind
	 slower redisplay.  */
      if (!inhibit_compacting_font_caches
	  && CONSP (cache))
	{
	  Lisp_Object entry;

	  for (entry = XCDR (cache); CONSP (entry); entry = XCDR (entry))
	    XSETCAR (entry, compact_font_cache_entry (XCAR (entry)));
	}
      mark_object (cache);
    }
}

#else /* not HAVE_WINDOW_SYSTEM */

#define compact_font_caches() (void)(0)

#endif /* HAVE_WINDOW_SYSTEM */

/* Remove (MARKER . DATA) entries with unmarked MARKER
   from buffer undo LIST and return changed list.  */

static Lisp_Object
compact_undo_list (Lisp_Object list)
{
  Lisp_Object tail, *prev = &list;

  for (tail = list; CONSP (tail); tail = XCDR (tail))
    {
      if (CONSP (XCAR (tail))
	  && MARKERP (XCAR (XCAR (tail)))
	  && !vectorlike_marked_p (&XMARKER (XCAR (XCAR (tail)))->header))
	*prev = XCDR (tail);
      else
	prev = xcdr_addr (tail);
    }
  return list;
}

static void
mark_pinned_objects (void)
{
  for (struct pinned_object *pobj = pinned_objects; pobj; pobj = pobj->next)
    mark_object (pobj->object);
}

static void
mark_pinned_symbols (void)
{
  struct symbol_block *sblk;
  int lim = (symbol_block_pinned == symbol_block
	     ? symbol_block_index : BLOCK_NSYMBOLS);

  for (sblk = symbol_block_pinned; sblk; sblk = sblk->next)
    {
      struct Lisp_Symbol *sym = sblk->symbols, *end = sym + lim;
      for (; sym < end; ++sym)
	if (sym->u.s.pinned)
	  mark_object (make_lisp_symbol (sym));

      lim = BLOCK_NSYMBOLS;
    }
}

static void
mark_most_objects (void)
{
  const struct Lisp_Vector *vbuffer_slot_defaults =
    (struct Lisp_Vector *) &buffer_slot_defaults;
  const struct Lisp_Vector *vbuffer_slot_symbols =
    (struct Lisp_Vector *) &buffer_slot_symbols;

  for (int i = 0; i < BUFFER_LISP_SIZE; ++i)
    {
      mark_object (vbuffer_slot_defaults->contents[i]);
      mark_object (vbuffer_slot_symbols->contents[i]);
    }

  for (int i = 0; i < ARRAYELTS (lispsym); ++i)
    mark_object (builtin_lisp_symbol (i));

  // defvar_lisp calls staticpro.
  for (int i = 0; i < staticidx; ++i)
    mark_object (*staticvec[i]);
}

/* List of weak hash tables we found during marking the Lisp heap.
   NULL on entry to garbage_collect and after it returns.  */
static struct Lisp_Hash_Table *weak_hash_tables;

static void
mark_and_sweep_weak_table_contents (void)
{
  struct Lisp_Hash_Table *h;
  bool marked;

  /* Mark all keys and values that are in use.  Keep on marking until
     there is no more change.  This is necessary for cases like
     value-weak table A containing an entry X -> Y, where Y is used in a
     key-weak table B, Z -> Y.  If B comes after A in the list of weak
     tables, X -> Y might be removed from A, although when looking at B
     one finds that it shouldn't.  */
  do
    {
      marked = false;
      for (h = weak_hash_tables; h; h = h->next_weak)
        marked |= sweep_weak_table (h, false);
    }
  while (marked);

  /* Remove hash table entries that aren't used.  */
  while (weak_hash_tables)
    {
      h = weak_hash_tables;
      weak_hash_tables = h->next_weak;
      h->next_weak = NULL;
      sweep_weak_table (h, true);
    }
}

/* The looser of the threshold and percentage constraints prevails.  */
static void
update_bytes_between_gc (void)
{
  intmax_t threshold0 = gc_cons_threshold;
  intmax_t threshold1 = FLOATP (Vgc_cons_percentage)
    ? XFLOAT_DATA (Vgc_cons_percentage) * total_bytes_of_live_objects ()
    : threshold0;
  bytes_between_gc = max (threshold0, threshold1);
}

/* Immediately adjust bytes_between_gc for changes to
   gc-cons-threshold.  */
static Lisp_Object
watch_gc_cons_threshold (Lisp_Object symbol, Lisp_Object newval,
			 Lisp_Object operation, Lisp_Object where)
{
  if (INTEGERP (newval))
    {
      intmax_t threshold;
      if (integer_to_intmax (newval, &threshold))
	{
	  gc_cons_threshold = max (threshold, GC_DEFAULT_THRESHOLD >> 3);
	  update_bytes_between_gc ();
	}
    }
  return Qnil;
}

/* Immediately adjust bytes_between_gc for changes to
   gc-cons-percentage.  */
static Lisp_Object
watch_gc_cons_percentage (Lisp_Object symbol, Lisp_Object newval,
			  Lisp_Object operation, Lisp_Object where)
{
  if (FLOATP (newval))
    {
      Vgc_cons_percentage = newval;
      update_bytes_between_gc ();
    }
  return Qnil;
}

static inline bool mark_stack_empty_p (void);

/* Subroutine of Fgarbage_collect that does most of the work.  */
void
garbage_collect (void)
{
  static struct timespec gc_elapsed = {0, 0};
  Lisp_Object tail, buffer;
  bool message_p = false;
  specpdl_ref count = SPECPDL_INDEX ();
  struct timespec start;

  eassert (weak_hash_tables == NULL);

  if (gc_inhibited || gc_in_progress)
    return;

  gc_in_progress = true;

  eassert (mark_stack_empty_p ());

  /* Show up in profiler.  */
  record_in_backtrace (QAutomatic_GC, 0, 0);

  /* Do this early in case user quits.  */
  FOR_EACH_LIVE_BUFFER (tail, buffer)
    compact_buffer (XBUFFER (buffer));

  size_t tot_before = (profiler_memory_running
		       ? total_bytes_of_live_objects ()
		       : (size_t) -1);

  start = current_timespec ();

  /* Save what's currently displayed in the echo area.  Don't do that
     if we are GC'ing because we've run out of memory, since
     push_message will cons, and we might have no memory for that.  */
  if (NILP (Vmemory_full))
    {
      message_p = push_message ();
      record_unwind_protect_void (pop_message_unwind);
    }

  if (garbage_collection_messages)
    message1_nolog ("Garbage collecting...");

  block_input ();

  shrink_regexp_cache ();

  mark_most_objects ();
  mark_pinned_objects ();
  mark_pinned_symbols ();
  mark_terminals ();
  mark_kboards ();
  mark_threads ();

#ifdef HAVE_PGTK
  mark_pgtkterm ();
#endif

#ifdef USE_GTK
  xg_mark_data ();
#endif

#ifdef HAVE_HAIKU
  mark_haiku_display ();
#endif

#ifdef HAVE_WINDOW_SYSTEM
  mark_fringe_data ();
#endif

#ifdef HAVE_X_WINDOWS
  mark_xterm ();
#endif

  /* Everything is now marked, except for font caches, undo lists, and
     finalizers.  The first two admit compaction before marking.
     All finalizers, even unmarked ones, need to run after sweep,
     so survive the unmarked ones in doomed_finalizers.  */

  compact_font_caches ();

  FOR_EACH_LIVE_BUFFER (tail, buffer)
    {
      struct buffer *b = XBUFFER (buffer);
      if (! EQ (BVAR (b, undo_list), Qt))
	bset_undo_list (b, compact_undo_list (BVAR (b, undo_list)));
      mark_object (BVAR (b, undo_list));
    }

  queue_doomed_finalizers (&doomed_finalizers, &finalizers);
  mark_finalizer_list (&doomed_finalizers);

  /* Must happen after all other marking and before gc_sweep.  */
  mark_and_sweep_weak_table_contents ();
  eassert (weak_hash_tables == NULL);

  eassert (mark_stack_empty_p ());

  gc_sweep ();

  unmark_main_thread ();

  bytes_since_gc = 0;

  update_bytes_between_gc ();

  /* Unblock as late as possible since it could signal (Bug#43389).  */
  unblock_input ();

  if (garbage_collection_messages && NILP (Vmemory_full))
    {
      if (message_p || minibuf_level > 0)
	restore_message ();
      else
	message1_nolog ("Garbage collecting...done");
    }

  unbind_to (count, Qnil);

  /* GC is complete: now we can run our finalizer callbacks.  */
  run_finalizers (&doomed_finalizers);

  if (! NILP (Vpost_gc_hook))
    {
      specpdl_ref gc_count = inhibit_garbage_collection ();
      safe_run_hooks (Qpost_gc_hook);
      unbind_to (gc_count, Qnil);
    }

  gc_in_progress = false;
  gc_elapsed = timespec_add (gc_elapsed,
			     timespec_sub (current_timespec (), start));
  Vgc_elapsed = make_float (timespectod (gc_elapsed));
  gcs_done++;

  /* Collect profiling data.  */
  if (tot_before != (size_t) -1)
    {
      size_t tot_after = total_bytes_of_live_objects ();
      if (tot_after < tot_before)
	malloc_probe (min (tot_before - tot_after, SIZE_MAX));
    }
}

DEFUN ("garbage-collect", Fgarbage_collect, Sgarbage_collect, 0, 0, "",
       doc: /* Reclaim storage for no longer referenced objects.
Return a list of entries of the form (NAME SIZE USED FREE), where:
- NAME is the Lisp data type, e.g., "conses".
- SIZE is per-object bytes.
- USED is the live count.
- FREE is the free-list count, i.e., reclaimed and redeployable objects.

For further details, see Info node `(elisp)Garbage Collection'.  */)
  (void)
{
  if (gc_inhibited)
    return Qnil;

  garbage_collect ();

  Lisp_Object total[] = {
    list4 (Qconses, make_fixnum (sizeof (struct Lisp_Cons)),
	   make_int (gcstat.total_conses),
	   make_int (gcstat.total_free_conses)),
    list4 (Qsymbols, make_fixnum (sizeof (struct Lisp_Symbol)),
	   make_int (gcstat.total_symbols),
	   make_int (gcstat.total_free_symbols)),
    list4 (Qstrings, make_fixnum (sizeof (struct Lisp_String)),
	   make_int (gcstat.total_strings),
	   make_int (gcstat.total_free_strings)),
    list3 (Qstring_bytes, make_fixnum (1),
	   make_int (gcstat.total_string_bytes)),
    list3 (Qvectors,
	   make_fixnum (header_size + sizeof (Lisp_Object)),
	   make_int (gcstat.total_vectors)),
    list4 (Qvector_slots, make_fixnum (word_size),
	   make_int (gcstat.total_vector_slots),
	   make_int (gcstat.total_free_vector_slots)),
    list4 (Qfloats, make_fixnum (sizeof (struct Lisp_Float)),
	   make_int (gcstat.total_floats),
	   make_int (gcstat.total_free_floats)),
    list4 (Qintervals, make_fixnum (sizeof (struct interval)),
	   make_int (gcstat.total_intervals),
	   make_int (gcstat.total_free_intervals)),
    list3 (Qbuffers, make_fixnum (sizeof (struct buffer)),
	   make_int (gcstat.total_buffers)),
  };
  return CALLMANY (Flist, total);
}

DEFUN ("garbage-collect-maybe", Fgarbage_collect_maybe,
Sgarbage_collect_maybe, 1, 1, 0,
       doc: /* Call `garbage-collect' if enough allocation happened.
FACTOR determines what "enough" means here:
If FACTOR is a positive number N, it means to run GC if more than
1/Nth of the allocations needed to trigger automatic allocation took
place.
Therefore, as N gets higher, this is more likely to perform a GC.
Returns non-nil if GC happened, and nil otherwise.  */)
  (Lisp_Object factor)
{
  CHECK_FIXNAT (factor);
  EMACS_INT fact = XFIXNAT (factor);

  if (fact >= 1 && bytes_since_gc > bytes_between_gc / fact)
    {
      garbage_collect ();
      return Qt;
    }
  else
    return Qnil;
}

/* Mark Lisp objects in glyph matrix MATRIX.  Currently the
   only interesting objects referenced from glyphs are strings.  */

static void
mark_glyph_matrix (struct glyph_matrix *matrix)
{
  struct glyph_row *row = matrix->rows;
  struct glyph_row *end = row + matrix->nrows;

  for (; row < end; ++row)
    if (row->enabled_p)
      {
	int area;
	for (area = LEFT_MARGIN_AREA; area < LAST_AREA; ++area)
	  {
	    struct glyph *glyph = row->glyphs[area];
	    struct glyph *end_glyph = glyph + row->used[area];

	    for (; glyph < end_glyph; ++glyph)
	      if (STRINGP (glyph->object)
		  && !string_marked_p (XSTRING (glyph->object)))
		mark_object (glyph->object);
	  }
      }
}

/* Whether to remember a few of the last marked values for debugging.  */
#define GC_REMEMBER_LAST_MARKED 0

#if GC_REMEMBER_LAST_MARKED
enum { LAST_MARKED_SIZE = 1 << 9 }; /* Must be a power of 2.  */
Lisp_Object last_marked[LAST_MARKED_SIZE] EXTERNALLY_VISIBLE;
static int last_marked_index;
#endif

/* Whether to enable the mark_object_loop_halt debugging feature.  */
#define GC_CDR_COUNT 0

#if GC_CDR_COUNT
/* For debugging--call abort when we cdr down this many
   links of a list, in mark_object.  In debugging,
   the call to abort will hit a breakpoint.
   Normally this is zero and the check never goes off.  */
ptrdiff_t mark_object_loop_halt EXTERNALLY_VISIBLE;
#endif

static void
mark_vectorlike (union vectorlike_header *header)
{
  struct Lisp_Vector *ptr = (struct Lisp_Vector *) header;
  ptrdiff_t size = ptr->header.size;
  if (size & PSEUDOVECTOR_FLAG)
    {
      /* Bool vectors have a different case in mark_object.  */
      eassert (PSEUDOVECTOR_TYPE (ptr) != PVEC_BOOL_VECTOR);
      /* Number of Lisp_Object fields.  */
      size &= PSEUDOVECTOR_SIZE_MASK;
    }
  eassert (! vectorlike_marked_p (header));
  set_vectorlike_marked (header);
  mark_objects (ptr->contents, size);
}

/* Like mark_vectorlike but optimized for char-tables (and
   sub-char-tables) assuming that the contents are mostly integers or
   symbols.  */

static void
mark_char_table (struct Lisp_Vector *ptr, enum pvec_type pvectype)
{
  int size = ptr->header.size & PSEUDOVECTOR_SIZE_MASK;
  /* Consult the Lisp_Sub_Char_Table layout before changing this.  */
  int i, idx = (pvectype == PVEC_SUB_CHAR_TABLE ? SUB_CHAR_TABLE_OFFSET : 0);

  eassert (!vector_marked_p (ptr));
  set_vector_marked (ptr);
  for (i = idx; i < size; i++)
    {
      Lisp_Object val = ptr->contents[i];

      if (FIXNUMP (val) ||
          (SYMBOLP (val) && symbol_marked_p (XSYMBOL (val))))
	continue;
      if (SUB_CHAR_TABLE_P (val))
	{
	  if (! vector_marked_p (XVECTOR (val)))
	    mark_char_table (XVECTOR (val), PVEC_SUB_CHAR_TABLE);
	}
      else
	mark_object (val);
    }
}

/* Mark the chain of overlays starting at PTR.  */

static void
mark_overlay (struct Lisp_Overlay *ptr)
{
  for (; ptr && !vectorlike_marked_p (&ptr->header); ptr = ptr->next)
    {
      set_vectorlike_marked (&ptr->header);
      /* These two are always markers and can be marked fast.  */
      set_vectorlike_marked (&XMARKER (ptr->start)->header);
      set_vectorlike_marked (&XMARKER (ptr->end)->header);
      mark_object (ptr->plist);
    }
}

/* Mark Lisp_Objects and special pointers in BUFFER.  */

static void
mark_buffer (struct buffer *buffer)
{
  /* This is handled much like other pseudovectors...  */
  mark_vectorlike (&buffer->header);

  /* ...but there are some buffer-specific things.  */

  mark_interval_tree (buffer_intervals (buffer));

  /* For now, we just don't mark the undo_list.  It's done later in
     a special way just before the sweep phase, and after stripping
     some of its elements that are not needed any more.
     Note: this later processing is only done for live buffers, so
     for dead buffers, the undo_list should be nil (set by Fkill_buffer),
     but just to be on the safe side, we mark it here.  */
  if (!BUFFER_LIVE_P (buffer))
      mark_object (BVAR (buffer, undo_list));

  mark_overlay (buffer->overlays_before);
  mark_overlay (buffer->overlays_after);

  /* If this is an indirect buffer, mark its base buffer.  */
  if (buffer->base_buffer &&
      !vectorlike_marked_p (&buffer->base_buffer->header))
    mark_buffer (buffer->base_buffer);
}

/* Mark Lisp faces in the face cache C.  */

static void
mark_face_cache (struct face_cache *c)
{
  if (c)
    {
      for (int i = 0; i < c->used; i++)
	{
	  struct face *face = FACE_FROM_ID_OR_NULL (c->f, i);

	  if (face)
	    {
	      if (face->font && !vectorlike_marked_p (&face->font->header))
		mark_vectorlike (&face->font->header);

	      mark_objects (face->lface, LFACE_VECTOR_SIZE);
	    }
	}
    }
}

static void
mark_localized_symbol (struct Lisp_Symbol *ptr)
{
  struct Lisp_Buffer_Local_Value *blv = SYMBOL_BLV (ptr);
  /* If the value is set up for a killed buffer restore its global binding.  */
  if (BUFFERP (blv->where) && ! BUFFER_LIVE_P (XBUFFER (blv->where)))
    symval_restore_default (ptr);
  mark_object (blv->where);
  mark_object (blv->valcell);
  mark_object (blv->defcell);
}

/* Remove killed buffers or items whose car is a killed buffer from
   LIST, and mark other items.  Return changed LIST, which is marked.  */

static Lisp_Object
mark_discard_killed_buffers (Lisp_Object list)
{
  Lisp_Object tail, *prev = &list;

  for (tail = list; CONSP (tail) && !cons_marked_p (XCONS (tail));
       tail = XCDR (tail))
    {
      Lisp_Object tem = XCAR (tail);
      if (CONSP (tem))
	tem = XCAR (tem);
      if (BUFFERP (tem) && !BUFFER_LIVE_P (XBUFFER (tem)))
	*prev = XCDR (tail);
      else
	{
	  set_cons_marked (XCONS (tail));
	  mark_object (XCAR (tail));
	  prev = xcdr_addr (tail);
	}
    }
  mark_object (tail);
  return list;
}

static void
mark_frame (struct Lisp_Vector *ptr)
{
  struct frame *f = (struct frame *) ptr;
  mark_vectorlike (&ptr->header);
  mark_face_cache (f->face_cache);
#ifdef HAVE_WINDOW_SYSTEM
  if (FRAME_WINDOW_P (f) && FRAME_OUTPUT_DATA (f))
    {
      struct font *font = FRAME_FONT (f);

      if (font && !vectorlike_marked_p (&font->header))
        mark_vectorlike (&font->header);
    }
#endif
}

static void
mark_window (struct Lisp_Vector *ptr)
{
  struct window *w = (struct window *) ptr;

  mark_vectorlike (&ptr->header);

  /* Mark glyph matrices, if any.  Marking window
     matrices is sufficient because frame matrices
     use the same glyph memory.  */
  if (w->current_matrix)
    {
      mark_glyph_matrix (w->current_matrix);
      mark_glyph_matrix (w->desired_matrix);
    }

  /* Filter out killed buffers from both buffer lists
     in attempt to help GC to reclaim killed buffers faster.
     We can do it elsewhere for live windows, but this is the
     best place to do it for dead windows.  */
  wset_prev_buffers
    (w, mark_discard_killed_buffers (w->prev_buffers));
  wset_next_buffers
    (w, mark_discard_killed_buffers (w->next_buffers));
}

/* Entry of the mark stack.  */
struct mark_entry
{
  ptrdiff_t n;		        /* number of values, or 0 if a single value */
  union {
    Lisp_Object value;		/* when n = 0 */
    Lisp_Object *values;	/* when n > 0 */
  } u;
};

/* This stack is used during marking for traversing data structures without
   using C recursion.  */
struct mark_stack
{
  struct mark_entry *stack;	/* base of stack */
  ptrdiff_t size;		/* allocated size in entries */
  ptrdiff_t sp;			/* current number of entries */
};

static struct mark_stack mark_stk = {NULL, 0, 0};

static inline bool
mark_stack_empty_p (void)
{
  return mark_stk.sp <= 0;
}

/* Pop and return a value from the mark stack (which must be nonempty).  */
static inline Lisp_Object
mark_stack_pop (void)
{
  eassume (!mark_stack_empty_p ());
  struct mark_entry *e = &mark_stk.stack[mark_stk.sp - 1];
  if (e->n == 0)		/* single value */
    {
      --mark_stk.sp;
      return e->u.value;
    }
  /* Array of values: pop them left to right, which seems to be slightly
     faster than right to left.  */
  e->n--;
  if (e->n == 0)
    --mark_stk.sp;		/* last value consumed */
  return (++e->u.values)[-1];
}

static void
grow_mark_stack (void)
{
  struct mark_stack *ms = &mark_stk;
  eassert (ms->sp == ms->size);
  ptrdiff_t min_incr = ms->sp == 0 ? 8192 : 1;
  ms->stack = xpalloc (ms->stack, &ms->size, min_incr, -1, sizeof *ms->stack);
  eassert (ms->sp < ms->size);
}

static inline void
mark_stack_push (Lisp_Object value)
{
  if (mark_stk.sp >= mark_stk.size)
    grow_mark_stack ();
  mark_stk.stack[mark_stk.sp++] =
    (struct mark_entry) {.n = 0, .u.value = value};
}

static inline void
mark_stack_push_n (Lisp_Object *values, ptrdiff_t n)
{
  if (n > 0)
    {
      if (mark_stk.sp >= mark_stk.size)
	grow_mark_stack ();
      mark_stk.stack[mark_stk.sp++] =
	(struct mark_entry) {.n = n, .u.values = values};
    }
}

/* Traverse and mark objects on the mark stack above BASE_SP.

   Traversal is depth-first using the mark stack for most common
   object types.  Recursion is used for other types whose object
   depths presumably wouldn't overwhelm the call stack.  */
static void
process_mark_stack (ptrdiff_t base_sp)
{
#if GC_CHECK_MARKED_OBJECTS
  struct mem_node *m = NULL;
#endif
#if GC_CDR_COUNT
  ptrdiff_t cdr_count = 0;
#endif

  eassume (mark_stk.sp >= base_sp && base_sp >= 0);

  while (mark_stk.sp > base_sp)
    {
      Lisp_Object obj = mark_stack_pop ();
    mark_obj: ;
      void *po = XPNTR (obj);
      if (PURE_P (po))
	continue;

#if GC_REMEMBER_LAST_MARKED
      last_marked[last_marked_index++] = obj;
      last_marked_index &= LAST_MARKED_SIZE - 1;
#endif

      /* Perform some sanity checks on the objects marked here.  Abort if
	 we encounter an object we know is bogus.  This increases GC time
	 by ~80%.  */
#if GC_CHECK_MARKED_OBJECTS

      /* Check that the object pointed to by PO is known to be a Lisp
	 structure allocated from the heap.  */
#define CHECK_ALLOCATED()				\
      do {						\
	if (pdumper_object_p (po))			\
	  {						\
	    if (! pdumper_object_p_precise (po))	\
	      emacs_abort ();				\
	    break;					\
	  }						\
	m = mem_find (po);				\
	if (m == MEM_NIL)				\
	  emacs_abort ();				\
      } while (0)

      /* Check that the object pointed to by PO is live, using predicate
	 function LIVEP.  */
#define CHECK_LIVE(LIVEP, MEM_TYPE)			\
      do {						\
	if (pdumper_object_p (po))			\
	  break;					\
	if (! (m->type == MEM_TYPE && LIVEP (m, po)))	\
	  emacs_abort ();				\
      } while (0)

      /* Check both of the above conditions, for non-symbols.  */
#define CHECK_ALLOCATED_AND_LIVE(LIVEP, MEM_TYPE)	\
      do {						\
	CHECK_ALLOCATED ();				\
	CHECK_LIVE (LIVEP, MEM_TYPE);			\
      } while (false)

      /* Check both of the above conditions, for symbols.  */
#define CHECK_ALLOCATED_AND_LIVE_SYMBOL()			\
      do {							\
	if (! c_symbol_p (ptr))					\
	  {							\
	    CHECK_ALLOCATED ();					\
	    CHECK_LIVE (live_symbol_p, MEM_TYPE_SYMBOL);	\
	  }							\
      } while (false)

#else /* not GC_CHECK_MARKED_OBJECTS */

#define CHECK_ALLOCATED_AND_LIVE(LIVEP, MEM_TYPE)	((void) 0)
#define CHECK_ALLOCATED_AND_LIVE_SYMBOL()		((void) 0)

#endif /* not GC_CHECK_MARKED_OBJECTS */

      switch (XTYPE (obj))
	{
	case Lisp_String:
	  {
	    register struct Lisp_String *ptr = XSTRING (obj);
	    if (string_marked_p (ptr))
	      break;
	    CHECK_ALLOCATED_AND_LIVE (live_string_p, MEM_TYPE_STRING);
	    set_string_marked (ptr);
	    mark_interval_tree (ptr->u.s.intervals);
#ifdef GC_CHECK_STRING_BYTES
	    /* Check that the string size recorded in the string is the
	       same as the one recorded in the sdata structure.  */
	    string_bytes (ptr);
#endif /* GC_CHECK_STRING_BYTES */
	  }
	  break;

	case Lisp_Vectorlike:
	  {
	    register struct Lisp_Vector *ptr = XVECTOR (obj);

	    if (vector_marked_p (ptr))
	      break;

	    enum pvec_type pvectype = PSEUDOVECTOR_TYPE (ptr);

#ifdef GC_CHECK_MARKED_OBJECTS
	    if (! pdumper_object_p (po) && ! SUBRP (obj) && ! main_thread_p (po))
	      {
		m = mem_find (po);
		if (m == MEM_NIL)
		  emacs_abort ();
		if (m->type == MEM_TYPE_VECTORLIKE)
		  CHECK_LIVE (live_large_vector_p, MEM_TYPE_VECTORLIKE);
		else
		  CHECK_LIVE (live_small_vector_p, MEM_TYPE_VBLOCK);
	      }
#endif

	    switch (pvectype)
	      {
	      case PVEC_BUFFER:
		mark_buffer ((struct buffer *) ptr);
		break;

	      case PVEC_FRAME:
		mark_frame (ptr);
		break;

	      case PVEC_WINDOW:
		mark_window (ptr);
		break;

	      case PVEC_HASH_TABLE:
		{
		  struct Lisp_Hash_Table *h = (struct Lisp_Hash_Table *)ptr;
		  ptrdiff_t size = ptr->header.size & PSEUDOVECTOR_SIZE_MASK;
		  set_vector_marked (ptr);
		  mark_stack_push_n (ptr->contents, size);
		  mark_stack_push (h->test.name);
		  mark_stack_push (h->test.user_hash_function);
		  mark_stack_push (h->test.user_cmp_function);
		  if (NILP (h->weak))
		    mark_stack_push (h->key_and_value);
		  else
		    {
		      /* For weak tables, mark only the vector and not its
			 contents --- that's what makes it weak.  */
		      eassert (h->next_weak == NULL);
		      h->next_weak = weak_hash_tables;
		      weak_hash_tables = h;
		      set_vector_marked (XVECTOR (h->key_and_value));
		    }
		  break;
		}

	      case PVEC_CHAR_TABLE:
	      case PVEC_SUB_CHAR_TABLE:
		mark_char_table (ptr, (enum pvec_type) pvectype);
		break;

	      case PVEC_BOOL_VECTOR:
		/* bool vectors in a dump are permanently "marked", since
		   they're in the old section and don't have mark bits.
		   If we're looking at a dumped bool vector, we should
		   have aborted above when we called vector_marked_p, so
		   we should never get here.  */
		eassert (! pdumper_object_p (ptr));
		set_vector_marked (ptr);
		break;

	      case PVEC_OVERLAY:
		mark_overlay (XOVERLAY (obj));
		break;

	      case PVEC_SUBR:
#ifdef HAVE_NATIVE_COMP
		if (SUBR_NATIVE_COMPILEDP (obj))
		  {
		    set_vector_marked (ptr);
		    struct Lisp_Subr *subr = XSUBR (obj);
		    mark_stack_push (subr->intspec.native);
		    mark_stack_push (subr->command_modes);
		    mark_stack_push (subr->native_comp_u);
		    mark_stack_push (subr->lambda_list);
		    mark_stack_push (subr->type);
		  }
#endif
		break;

	      case PVEC_FREE:
		emacs_abort ();

	      default:
		{
		  /* Same as mark_vectorlike() except stack push
		     versus recursive call to mark_objects().  */
		  ptrdiff_t size = ptr->header.size;
		  if (size & PSEUDOVECTOR_FLAG)
		    size &= PSEUDOVECTOR_SIZE_MASK;
		  set_vector_marked (ptr);
		  mark_stack_push_n (ptr->contents, size);
		}
		break;
	      }
	  }
	  break;

	case Lisp_Symbol:
	  {
	    struct Lisp_Symbol *ptr = XSYMBOL (obj);
	  nextsym:
	    if (symbol_marked_p (ptr))
	      break;
	    CHECK_ALLOCATED_AND_LIVE_SYMBOL ();
	    set_symbol_marked (ptr);
	    /* Attempt to catch bogus objects.  */
	    eassert (valid_lisp_object_p (ptr->u.s.function));
	    mark_stack_push (ptr->u.s.function);
	    mark_stack_push (ptr->u.s.plist);
	    switch (ptr->u.s.redirect)
	      {
	      case SYMBOL_PLAINVAL:
		mark_stack_push (SYMBOL_VAL (ptr));
		break;
	      case SYMBOL_VARALIAS:
		{
		  Lisp_Object tem;
		  XSETSYMBOL (tem, SYMBOL_ALIAS (ptr));
		  mark_stack_push (tem);
		  break;
		}
	      case SYMBOL_LOCALIZED:
		mark_localized_symbol (ptr);
		break;
	      case SYMBOL_FORWARDED:
		/* If the value is forwarded to a buffer or keyboard field,
		   these are marked when we see the corresponding object.
		   And if it's forwarded to a C variable, either it's not
		   a Lisp_Object var, or it's staticpro'd already.  */
		break;
	      default: emacs_abort ();
	      }
	    if (!PURE_P (XSTRING (ptr->u.s.name)))
	      set_string_marked (XSTRING (ptr->u.s.name));
	    mark_interval_tree (string_intervals (ptr->u.s.name));
	    /* Inner loop to mark next symbol in this bucket, if any.  */
	    po = ptr = ptr->u.s.next;
	    if (ptr)
	      goto nextsym;
	  }
	  break;

	case Lisp_Cons:
	  {
	    struct Lisp_Cons *ptr = XCONS (obj);
	    if (cons_marked_p (ptr))
	      break;
	    CHECK_ALLOCATED_AND_LIVE (live_cons_p, MEM_TYPE_CONS);
	    set_cons_marked (ptr);
	    /* Avoid growing the stack if the cdr is nil.
	       In any case, make sure the car is expanded first.  */
	    if (!NILP (ptr->u.s.u.cdr))
	      {
		mark_stack_push (ptr->u.s.u.cdr);
#if GC_CDR_COUNT
		cdr_count++;
		if (cdr_count == mark_object_loop_halt)
		  emacs_abort ();
#endif
	      }
	    /* Speedup hack for the common case (successive list elements).  */
	    obj = ptr->u.s.car;
	    goto mark_obj;
	  }

	case Lisp_Float:
	  CHECK_ALLOCATED_AND_LIVE (live_float_p, MEM_TYPE_FLOAT);
	  /* Do not mark floats stored in a dump image: these floats are
	     "cold" and do not have mark bits.  */
	  if (pdumper_object_p (XFLOAT (obj)))
	    eassert (pdumper_cold_object_p (XFLOAT (obj)));
	  else if (!XFLOAT_MARKED_P (XFLOAT (obj)))
	    XFLOAT_MARK (XFLOAT (obj));
	  break;

	case_Lisp_Int:
	  break;

	default:
	  emacs_abort ();
	}
    }

#undef CHECK_LIVE
#undef CHECK_ALLOCATED
#undef CHECK_ALLOCATED_AND_LIVE
}

void
mark_object (Lisp_Object obj)
{
  ptrdiff_t sp = mark_stk.sp;
  mark_stack_push (obj);
  process_mark_stack (sp);
}

void
mark_objects (Lisp_Object *objs, ptrdiff_t n)
{
  ptrdiff_t sp = mark_stk.sp;
  mark_stack_push_n (objs, n);
  process_mark_stack (sp);
}

/* Mark the Lisp pointers in the terminal objects.
   Called by Fgarbage_collect.  */

static void
mark_terminals (void)
{
  for (struct terminal *t = terminal_list;
       t != NULL;
       t = t->next_terminal)
    {
      eassert (t->name != NULL);
#ifdef HAVE_WINDOW_SYSTEM
      mark_image_cache (t->image_cache);
#endif /* HAVE_WINDOW_SYSTEM */
      if (! vectorlike_marked_p (&t->header))
	mark_vectorlike (&t->header);
    }
}

/* Value is non-zero if OBJ will survive the current GC because it's
   either marked or does not need to be marked to survive.  */

bool
survives_gc_p (Lisp_Object obj)
{
  bool survives_p;

  switch (XTYPE (obj))
    {
    case_Lisp_Int:
      survives_p = true;
      break;

    case Lisp_Symbol:
      survives_p = symbol_marked_p (XSYMBOL (obj));
      break;

    case Lisp_String:
      survives_p = string_marked_p (XSTRING (obj));
      break;

    case Lisp_Vectorlike:
      survives_p =
	(SUBRP (obj) && !SUBR_NATIVE_COMPILEDP (obj)) ||
	vector_marked_p (XVECTOR (obj));
      break;

    case Lisp_Cons:
      survives_p = cons_marked_p (XCONS (obj));
      break;

    case Lisp_Float:
      survives_p =
        XFLOAT_MARKED_P (XFLOAT (obj)) ||
        pdumper_object_p (XFLOAT (obj));
      break;

    default:
      emacs_abort ();
    }

  return survives_p || PURE_P (XPNTR (obj));
}

static void
sweep_conses (void)
{
  struct cons_block **cprev = &cons_block;
  int lim = cons_block_index;
  size_t num_free = 0, num_used = 0;

  cons_free_list = 0;

  for (struct cons_block *cblk; (cblk = *cprev); )
    {
      int i = 0;
      int this_free = 0;
      int ilim = (lim + BITS_PER_BITS_WORD - 1) / BITS_PER_BITS_WORD;

      /* Scan the mark bits an int at a time.  */
      for (i = 0; i < ilim; i++)
        {
          if (cblk->gcmarkbits[i] == BITS_WORD_MAX)
            {
              /* Fast path - all cons cells for this int are marked.  */
              cblk->gcmarkbits[i] = 0;
              num_used += BITS_PER_BITS_WORD;
            }
          else
            {
              /* Some cons cells for this int are not marked.
                 Find which ones, and free them.  */
              int start, pos, stop;

              start = i * BITS_PER_BITS_WORD;
              stop = lim - start;
              if (stop > BITS_PER_BITS_WORD)
                stop = BITS_PER_BITS_WORD;
              stop += start;

              for (pos = start; pos < stop; pos++)
                {
		  struct Lisp_Cons *acons = &cblk->conses[pos];
		  if (!XCONS_MARKED_P (acons))
                    {
                      this_free++;
                      cblk->conses[pos].u.s.u.chain = cons_free_list;
                      cons_free_list = &cblk->conses[pos];
                      cons_free_list->u.s.car = dead_object ();
                    }
                  else
                    {
                      num_used++;
		      XUNMARK_CONS (acons);
                    }
                }
            }
        }

      lim = BLOCK_NCONS;
      /* If this block contains only free conses and we have already
         seen more than two blocks worth of free conses then deallocate
         this block.  */
      if (this_free == BLOCK_NCONS && num_free > BLOCK_NCONS)
        {
          *cprev = cblk->next;
          /* Unhook from the free list.  */
          cons_free_list = cblk->conses[0].u.s.u.chain;
          lisp_align_free (cblk);
        }
      else
        {
          num_free += this_free;
          cprev = &cblk->next;
        }
    }
  gcstat.total_conses = num_used;
  gcstat.total_free_conses = num_free;
}

static void
sweep_floats (void)
{
  struct float_block **fprev = &float_block;
  int lim = float_block_index;
  size_t num_free = 0, num_used = 0;

  float_free_list = 0;

  for (struct float_block *fblk; (fblk = *fprev); )
    {
      int this_free = 0;
      for (int i = 0; i < lim; i++)
	{
	  struct Lisp_Float *afloat = &fblk->floats[i];
	  if (!XFLOAT_MARKED_P (afloat))
	    {
	      this_free++;
	      fblk->floats[i].u.chain = float_free_list;
	      float_free_list = &fblk->floats[i];
	    }
	  else
	    {
	      num_used++;
	      XFLOAT_UNMARK (afloat);
	    }
	}
      lim = BLOCK_NFLOATS;
      /* If this block contains only free floats and we have already
         seen more than two blocks worth of free floats then deallocate
         this block.  */
      if (this_free == BLOCK_NFLOATS && num_free > BLOCK_NFLOATS)
        {
          *fprev = fblk->next;
          /* Unhook from the free list.  */
          float_free_list = fblk->floats[0].u.chain;
          lisp_align_free (fblk);
        }
      else
        {
          num_free += this_free;
          fprev = &fblk->next;
        }
    }
  gcstat.total_floats = num_used;
  gcstat.total_free_floats = num_free;
}

static void
sweep_intervals (void)
{
  struct interval_block **iprev = &interval_block;
  int lim = interval_block_index;
  size_t num_free = 0, num_used = 0;

  interval_free_list = 0;

  for (struct interval_block *iblk; (iblk = *iprev); )
    {
      int this_free = 0;

      for (int i = 0; i < lim; i++)
        {
          if (!iblk->intervals[i].gcmarkbit)
            {
              set_interval_parent (&iblk->intervals[i], interval_free_list);
              interval_free_list = &iblk->intervals[i];
              this_free++;
            }
          else
            {
              num_used++;
              iblk->intervals[i].gcmarkbit = 0;
            }
        }
      lim = BLOCK_NINTERVALS;
      /* If this block contains only free intervals and we have already
         seen more than two blocks worth of free intervals then
         deallocate this block.  */
      if (this_free == BLOCK_NINTERVALS && num_free > BLOCK_NINTERVALS)
        {
          *iprev = iblk->next;
          /* Unhook from the free list.  */
          interval_free_list = INTERVAL_PARENT (&iblk->intervals[0]);
          lisp_free (iblk);
        }
      else
        {
          num_free += this_free;
          iprev = &iblk->next;
        }
    }
  gcstat.total_intervals = num_used;
  gcstat.total_free_intervals = num_free;
}

static void
sweep_symbols (void)
{
  struct symbol_block *sblk;
  struct symbol_block **sprev = &symbol_block;
  int lim = symbol_block_index;
  size_t num_free = 0, num_used = ARRAYELTS (lispsym);

  symbol_free_list = NULL;

  for (int i = 0; i < ARRAYELTS (lispsym); i++)
    lispsym[i].u.s.gcmarkbit = 0;

  for (sblk = symbol_block; sblk; sblk = *sprev)
    {
      int this_free = 0;
      struct Lisp_Symbol *sym = sblk->symbols;
      struct Lisp_Symbol *end = sym + lim;

      for (; sym < end; ++sym)
        {
          if (sym->u.s.gcmarkbit)
            {
              ++num_used;
              sym->u.s.gcmarkbit = 0;
              eassert (valid_lisp_object_p (sym->u.s.function));
            }
	  else
            {
              if (sym->u.s.redirect == SYMBOL_LOCALIZED)
		{
                  xfree (SYMBOL_BLV (sym));
                  /* Avoid re-free (bug#29066).  */
                  sym->u.s.redirect = SYMBOL_PLAINVAL;
                }
              sym->u.s.next = symbol_free_list;
              symbol_free_list = sym;
              symbol_free_list->u.s.function = dead_object ();
              ++this_free;
            }
        }

      lim = BLOCK_NSYMBOLS;
      /* If this block contains only free symbols and we have already
         seen more than two blocks worth of free symbols then deallocate
         this block.  */
      if (this_free == BLOCK_NSYMBOLS && num_free > BLOCK_NSYMBOLS)
        {
          *sprev = sblk->next;
          /* Unhook from the free list.  */
          symbol_free_list = sblk->symbols[0].u.s.next;
          lisp_free (sblk);
        }
      else
        {
          num_free += this_free;
          sprev = &sblk->next;
        }
    }
  gcstat.total_symbols = num_used;
  gcstat.total_free_symbols = num_free;
}

/* Markers are weak pointers.  Invalidate all markers pointing to the
   swept BUFFER.  */
static void
unchain_dead_markers (struct buffer *buffer)
{
  struct Lisp_Marker *this, **prev = &BUF_MARKERS (buffer);

  while ((this = *prev))
    if (vectorlike_marked_p (&this->header))
      prev = &this->next;
    else
      {
        this->buffer = NULL;
        *prev = this->next;
      }
}

static void
sweep_buffers (void)
{
  Lisp_Object tail, buf;

  gcstat.total_buffers = 0;
  FOR_EACH_LIVE_BUFFER (tail, buf)
    {
      struct buffer *buffer = XBUFFER (buf);
      /* Do not use buffer_(set|get)_intervals here.  */
      buffer->text->intervals = balance_intervals (buffer->text->intervals);
      unchain_dead_markers (buffer);
      gcstat.total_buffers++;
    }
}

/* Sweep: find all structures not marked, and free them.  */
static void
gc_sweep (void)
{
  sweep_strings ();
  check_string_bytes (!noninteractive);
  sweep_conses ();
  sweep_floats ();
  sweep_intervals ();
  sweep_symbols ();
  sweep_buffers ();
  sweep_vectors ();
  pdumper_clear_marks ();
  check_string_bytes (!noninteractive);
}

DEFUN ("memory-full", Fmemory_full, Smemory_full, 0, 0, 0,
       doc: /* Non-nil means Emacs cannot get much more Lisp memory.  */)
  (void)
{
  return Vmemory_full;
}

DEFUN ("memory-info", Fmemory_info, Smemory_info, 0, 0, 0,
       doc: /* Return a list of (TOTAL-RAM FREE-RAM TOTAL-SWAP FREE-SWAP).
All values are in Kbytes.  If there is no swap space,
last two values are zero.  If the system is not supported
or memory information can't be obtained, return nil.  */)
  (void)
{
#if defined HAVE_LINUX_SYSINFO
  struct sysinfo si;
  uintmax_t units;

  if (sysinfo (&si))
    return Qnil;
#ifdef LINUX_SYSINFO_UNIT
  units = si.mem_unit;
#else
  units = 1;
#endif
  return list4i ((uintmax_t) si.totalram * units / BLOCK_ALIGN,
		 (uintmax_t) si.freeram * units / BLOCK_ALIGN,
		 (uintmax_t) si.totalswap * units / BLOCK_ALIGN,
		 (uintmax_t) si.freeswap * units / BLOCK_ALIGN);
#elif defined WINDOWSNT
  unsigned long long totalram, freeram, totalswap, freeswap;

  if (w32_memory_info (&totalram, &freeram, &totalswap, &freeswap) == 0)
    return list4i ((uintmax_t) totalram / BLOCK_ALIGN,
		   (uintmax_t) freeram / BLOCK_ALIGN,
		   (uintmax_t) totalswap / BLOCK_ALIGN,
		   (uintmax_t) freeswap / BLOCK_ALIGN);
  else
    return Qnil;
#elif defined MSDOS
  unsigned long totalram, freeram, totalswap, freeswap;

  if (dos_memory_info (&totalram, &freeram, &totalswap, &freeswap) == 0)
    return list4i ((uintmax_t) totalram / BLOCK_ALIGN,
		   (uintmax_t) freeram / BLOCK_ALIGN,
		   (uintmax_t) totalswap / BLOCK_ALIGN,
		   (uintmax_t) freeswap / BLOCK_ALIGN);
  else
    return Qnil;
#else /* not HAVE_LINUX_SYSINFO, not WINDOWSNT, not MSDOS */
  /* FIXME: add more systems.  */
  return Qnil;
#endif /* HAVE_LINUX_SYSINFO, not WINDOWSNT, not MSDOS */
}

/* Debugging aids.  */

DEFUN ("memory-use-counts", Fmemory_use_counts, Smemory_use_counts, 0, 0, 0,
       doc: /* Return a list of counters that measure how much consing there has been.
Each of these counters increments for a certain kind of object.
The counters wrap around from the largest positive integer to zero.
Garbage collection does not decrease them.
The elements of the value are as follows:
  (CONSES FLOATS VECTOR-CELLS SYMBOLS STRING-CHARS INTERVALS STRINGS)
All are in units of 1 = one object consed
except for VECTOR-CELLS and STRING-CHARS, which count the total length of
objects consed.
Frames, windows, buffers, and subprocesses count as vectors
  (but the contents of a buffer's text do not count here).  */)
  (void)
{
  return  list (make_int (cons_cells_consed),
		make_int (floats_consed),
		make_int (vector_cells_consed),
		make_int (symbols_consed),
		make_int (string_chars_consed),
		make_int (intervals_consed),
		make_int (strings_consed));
}

#if defined GNU_LINUX && defined __GLIBC__ && \
  (__GLIBC__ > 2 || __GLIBC_MINOR__ >= 10)
DEFUN ("malloc-info", Fmalloc_info, Smalloc_info, 0, 0, "",
       doc: /* Report malloc information to stderr.
This function outputs to stderr an XML-formatted
description of the current state of the memory-allocation
arenas.  */)
  (void)
{
  if (malloc_info (0, stderr))
    error ("malloc_info failed: %s", emacs_strerror (errno));
  return Qnil;
}
#endif

#ifdef HAVE_MALLOC_TRIM
DEFUN ("malloc-trim", Fmalloc_trim, Smalloc_trim, 0, 1, "",
       doc: /* Release free heap memory to the OS.
This function asks libc to return unused heap memory back to the operating
system.  This function isn't guaranteed to do anything, and is mainly
meant as a debugging tool.

If LEAVE_PADDING is given, ask the system to leave that much unused
space in the heap of the Emacs process.  This should be an integer, and if
not given, it defaults to 0.

This function returns nil if no memory could be returned to the
system, and non-nil if some memory could be returned.  */)
  (Lisp_Object leave_padding)
{
  int pad = 0;

  if (! NILP (leave_padding))
    {
      CHECK_FIXNAT (leave_padding);
      pad = XFIXNUM (leave_padding);
    }

  /* 1 means that memory was released to the system.  */
  if (malloc_trim (pad) == 1)
    return Qt;
  else
    return Qnil;
}
#endif

static bool
symbol_uses_obj (Lisp_Object symbol, Lisp_Object obj)
{
  struct Lisp_Symbol *sym = XSYMBOL (symbol);
  Lisp_Object val = find_symbol_value (symbol);
  return (EQ (val, obj)
	  || EQ (sym->u.s.function, obj)
	  || (! NILP (sym->u.s.function)
	      && COMPILEDP (sym->u.s.function)
	      && EQ (AREF (sym->u.s.function, COMPILED_BYTECODE), obj))
	  || (! NILP (val)
	      && COMPILEDP (val)
	      && EQ (AREF (val, COMPILED_BYTECODE), obj)));
}

/* Find at most FIND_MAX symbols which have OBJ as their value or
   function.  This is used in gdbinit's `xwhichsymbols' command.  */

Lisp_Object
which_symbols (Lisp_Object obj, EMACS_INT find_max)
{
   struct symbol_block *sblk;
   specpdl_ref gc_count = inhibit_garbage_collection ();
   Lisp_Object found = Qnil;

   if (! deadp (obj))
     {
       for (int i = 0; i < ARRAYELTS (lispsym); i++)
	 {
	   Lisp_Object sym = builtin_lisp_symbol (i);
	   if (symbol_uses_obj (sym, obj))
	     {
	       found = Fcons (sym, found);
	       if (--find_max == 0)
		 goto out;
	     }
	 }

       for (sblk = symbol_block; sblk; sblk = sblk->next)
	 {
	   struct Lisp_Symbol *asym = sblk->symbols;
	   int bn;

	   for (bn = 0; bn < BLOCK_NSYMBOLS; bn++, asym++)
	     {
	       if (sblk == symbol_block && bn >= symbol_block_index)
		 break;

	       Lisp_Object sym = make_lisp_symbol (asym);
	       if (symbol_uses_obj (sym, obj))
		 {
		   found = Fcons (sym, found);
		   if (--find_max == 0)
		     goto out;
		 }
	     }
	 }
     }

  out:
   return unbind_to (gc_count, found);
}

#ifdef SUSPICIOUS_OBJECT_CHECKING

static void *
find_suspicious_object_in_range (void *begin, void *end)
{
  char *begin_a = begin;
  char *end_a = end;
  int i;

  for (i = 0; i < ARRAYELTS (suspicious_objects); ++i)
    {
      char *suspicious_object = suspicious_objects[i];
      if (begin_a <= suspicious_object && suspicious_object < end_a)
	return suspicious_object;
    }

  return NULL;
}

static void
note_suspicious_free (void *ptr)
{
  struct suspicious_free_record *rec;

  rec = &suspicious_free_history[suspicious_free_history_index++];
  if (suspicious_free_history_index ==
      ARRAYELTS (suspicious_free_history))
    {
      suspicious_free_history_index = 0;
    }

  memset (rec, 0, sizeof (*rec));
  rec->suspicious_object = ptr;
  backtrace (&rec->backtrace[0], ARRAYELTS (rec->backtrace));
}

static void
detect_suspicious_free (void *ptr)
{
  int i;

  eassert (ptr != NULL);

  for (i = 0; i < ARRAYELTS (suspicious_objects); ++i)
    if (suspicious_objects[i] == ptr)
      {
        note_suspicious_free (ptr);
        suspicious_objects[i] = NULL;
      }
}

#endif /* SUSPICIOUS_OBJECT_CHECKING */

DEFUN ("suspicious-object", Fsuspicious_object, Ssuspicious_object, 1, 1, 0,
       doc: /* Return OBJ, maybe marking it for extra scrutiny.
If Emacs is compiled with suspicious object checking, capture
a stack trace when OBJ is freed in order to help track down
garbage collection bugs.  Otherwise, do nothing and return OBJ.   */)
   (Lisp_Object obj)
{
#ifdef SUSPICIOUS_OBJECT_CHECKING
  /* Right now, we care only about vectors.  */
  if (VECTORLIKEP (obj))
    {
      suspicious_objects[suspicious_object_index++] = XVECTOR (obj);
      if (suspicious_object_index == ARRAYELTS (suspicious_objects))
	suspicious_object_index = 0;
    }
#endif
  return obj;
}

#ifdef ENABLE_CHECKING

bool suppress_checking;

void
die (const char *msg, const char *file, int line)
{
  fprintf (stderr, "\r\n%s:%d: Emacs fatal error: assertion failed: %s\r\n",
	   file, line, msg);
  terminate_due_to_signal (SIGABRT, INT_MAX);
}

#endif /* ENABLE_CHECKING */

#if defined (ENABLE_CHECKING) && USE_STACK_LISP_OBJECTS

/* Stress alloca with inconveniently sized requests and check
   whether all allocated areas may be used for Lisp_Object.  */

static void
verify_alloca (void)
{
  int i;
  enum { ALLOCA_CHECK_MAX = 256 };
  /* Start from size of the smallest Lisp object.  */
  for (i = sizeof (struct Lisp_Cons); i <= ALLOCA_CHECK_MAX; i++)
    {
      void *ptr = alloca (i);
      make_lisp_ptr (ptr, Lisp_Cons);
    }
}

#else /* not ENABLE_CHECKING && USE_STACK_LISP_OBJECTS */

#define verify_alloca() ((void) 0)

#endif /* ENABLE_CHECKING && USE_STACK_LISP_OBJECTS */

static void init_runtime (void);

/* Like all init_*_once(), we should only ever call this in the
   bootstrap.

   Via pdumper_do_now_and_after_load(), the initialization
   of the runtime alloc infra happens in init_runtime().
*/

void
init_alloc_once (void)
{
  gc_inhibited = false;
  gc_cons_threshold = GC_DEFAULT_THRESHOLD;

  PDUMPER_REMEMBER_SCALAR (buffer_slot_defaults.header);
  PDUMPER_REMEMBER_SCALAR (buffer_slot_symbols.header);

  /* Nothing can be malloc'ed until init_runtime().  */
  pdumper_do_now_and_after_load (init_runtime);

  Vloadup_pure_table = CALLN (Fmake_hash_table, QCtest, Qequal, QCsize,
                              make_fixed_natnum (80000));
  update_bytes_between_gc ();
  verify_alloca ();
  init_strings ();
  init_vectors ();
}

static void
init_runtime (void)
{
  purebeg = PUREBEG;
  pure_size = PURESIZE;
  mem_init ();
  init_finalizer_list (&finalizers);
  init_finalizer_list (&doomed_finalizers);
}

void
syms_of_alloc (void)
{
  static struct Lisp_Objfwd const o_fwd
    = {Lisp_Fwd_Obj, &Vmemory_full};
  Vmemory_full = Qnil;
  defvar_lisp (&o_fwd, "memory-full"); // calls staticpro

  DEFVAR_INT ("gc-cons-threshold", gc_cons_threshold,
	      doc: /* Number of bytes of consing between garbage collections.
Garbage collection can happen automatically once this many bytes have been
allocated since the last garbage collection.  All data types count.

Garbage collection happens automatically only when `eval' is called.

By binding this temporarily to a large number, you can effectively
prevent garbage collection during a part of the program.
See also `gc-cons-percentage'.  */);

  DEFVAR_LISP ("gc-cons-percentage", Vgc_cons_percentage,
	       doc: /* Portion of the heap used for allocation.
Garbage collection can happen automatically once this portion of the heap
has been allocated since the last garbage collection.
If this portion is smaller than `gc-cons-threshold', this is ignored.  */);
  Vgc_cons_percentage = make_float (0.1);

  DEFVAR_INT ("pure-bytes-used", pure_bytes_used,
	      doc: /* Number of bytes of shareable Lisp data allocated so far.  */);

  DEFVAR_INT ("cons-cells-consed", cons_cells_consed,
	      doc: /* Number of cons cells that have been consed so far.  */);

  DEFVAR_INT ("floats-consed", floats_consed,
	      doc: /* Number of floats that have been consed so far.  */);

  DEFVAR_INT ("vector-cells-consed", vector_cells_consed,
	      doc: /* Number of vector cells that have been consed so far.  */);

  DEFVAR_INT ("symbols-consed", symbols_consed,
	      doc: /* Number of symbols that have been consed so far.  */);
  symbols_consed += ARRAYELTS (lispsym);

  DEFVAR_INT ("string-chars-consed", string_chars_consed,
	      doc: /* Number of string characters that have been consed so far.  */);

  DEFVAR_INT ("intervals-consed", intervals_consed,
	      doc: /* Number of intervals that have been consed so far.  */);

  DEFVAR_INT ("strings-consed", strings_consed,
	      doc: /* Number of strings that have been consed so far.  */);

  DEFVAR_LISP ("loadup-pure-table", Vloadup_pure_table,
	       doc: /* Allocate objects in pure space during loadup.el.  */);
  Vloadup_pure_table = Qnil;

  DEFVAR_BOOL ("garbage-collection-messages", garbage_collection_messages,
	       doc: /* Non-nil means display messages at start and end of garbage collection.  */);
  garbage_collection_messages = 0;

  DEFVAR_LISP ("post-gc-hook", Vpost_gc_hook,
	       doc: /* Hook run after garbage collection has finished.  */);
  Vpost_gc_hook = Qnil;
  DEFSYM (Qpost_gc_hook, "post-gc-hook");

  DEFVAR_LISP ("memory-signal-data", Vmemory_signal_data,
	       doc: /* Precomputed `signal' argument for memory-full error.  */);
  /* We build this in advance because if we wait until we need it, we might
     not be able to allocate the memory to hold it.  */
  Vmemory_signal_data
    = pure_list (Qerror,
		 build_pure_c_string ("Memory exhausted--use"
				      " M-x save-some-buffers then"
				      " exit and restart Emacs"));

  DEFSYM (Qconses, "conses");
  DEFSYM (Qsymbols, "symbols");
  DEFSYM (Qstrings, "strings");
  DEFSYM (Qvectors, "vectors");
  DEFSYM (Qfloats, "floats");
  DEFSYM (Qintervals, "intervals");
  DEFSYM (Qbuffers, "buffers");
  DEFSYM (Qstring_bytes, "string-bytes");
  DEFSYM (Qvector_slots, "vector-slots");
  DEFSYM (Qheap, "heap");
  DEFSYM (QAutomatic_GC, "Automatic GC");

  DEFSYM (Qgc_cons_percentage, "gc-cons-percentage");
  DEFSYM (Qgc_cons_threshold, "gc-cons-threshold");
  DEFSYM (Qchar_table_extra_slots, "char-table-extra-slots");

  DEFVAR_LISP ("gc-elapsed", Vgc_elapsed,
	       doc: /* Accumulated time elapsed in garbage collections.
The time is in seconds as a floating point value.  */);

  DEFVAR_INT ("gcs-done", gcs_done,
              doc: /* Accumulated number of garbage collections done.  */);
  gcs_done = 0;

  DEFVAR_INT ("integer-width", integer_width,
	      doc: /* Maximum number N of bits in safely-calculated integers.
Integers with absolute values less than 2**N do not signal a range error.
N should be nonnegative.  */);

  defsubr (&Scons);
  defsubr (&Slist);
  defsubr (&Svector);
  defsubr (&Srecord);
  defsubr (&Sbool_vector);
  defsubr (&Smake_byte_code);
  defsubr (&Smake_closure);
  defsubr (&Smake_list);
  defsubr (&Smake_vector);
  defsubr (&Smake_record);
  defsubr (&Smake_string);
  defsubr (&Smake_bool_vector);
  defsubr (&Smake_symbol);
  defsubr (&Smake_marker);
  defsubr (&Smake_finalizer);
  defsubr (&Spurecopy);
  defsubr (&Sgarbage_collect);
  defsubr (&Sgarbage_collect_maybe);
  defsubr (&Smemory_info);
  defsubr (&Smemory_full);
  defsubr (&Smemory_use_counts);
#if defined GNU_LINUX && defined __GLIBC__ && \
  (__GLIBC__ > 2 || __GLIBC_MINOR__ >= 10)

  defsubr (&Smalloc_info);
#endif
#ifdef HAVE_MALLOC_TRIM
  defsubr (&Smalloc_trim);
#endif
  defsubr (&Ssuspicious_object);

  Lisp_Object watcher;

  static union Aligned_Lisp_Subr Swatch_gc_cons_threshold =
     {{{ PSEUDOVECTOR_FLAG | (PVEC_SUBR << PSEUDOVECTOR_AREA_BITS) },
       { .a4 = watch_gc_cons_threshold },
       4, 4, "watch_gc_cons_threshold", {0}, lisp_h_Qnil}};
  XSETSUBR (watcher, &Swatch_gc_cons_threshold.s);
  Fadd_variable_watcher (Qgc_cons_threshold, watcher);

  static union Aligned_Lisp_Subr Swatch_gc_cons_percentage =
     {{{ PSEUDOVECTOR_FLAG | (PVEC_SUBR << PSEUDOVECTOR_AREA_BITS) },
       { .a4 = watch_gc_cons_percentage },
       4, 4, "watch_gc_cons_percentage", {0}, lisp_h_Qnil}};
  XSETSUBR (watcher, &Swatch_gc_cons_percentage.s);
  Fadd_variable_watcher (Qgc_cons_percentage, watcher);
}

#ifdef HAVE_X_WINDOWS
enum defined_HAVE_X_WINDOWS { defined_HAVE_X_WINDOWS = true };
#else
enum defined_HAVE_X_WINDOWS { defined_HAVE_X_WINDOWS = false };
#endif

#ifdef HAVE_PGTK
enum defined_HAVE_PGTK { defined_HAVE_PGTK = true };
#else
enum defined_HAVE_PGTK { defined_HAVE_PGTK = false };
#endif

/* When compiled with GCC, GDB might say "No enum type named
   pvec_type" if we don't have at least one symbol with that type, and
   then xbacktrace could fail.  Similarly for the other enums and
   their values.  Some non-GCC compilers don't like these constructs.  */
#ifdef __GNUC__
union
{
  enum CHARTAB_SIZE_BITS CHARTAB_SIZE_BITS;
  enum char_table_specials char_table_specials;
  enum char_bits char_bits;
  enum CHECK_LISP_OBJECT_TYPE CHECK_LISP_OBJECT_TYPE;
  enum DEFAULT_HASH_SIZE DEFAULT_HASH_SIZE;
  enum Lisp_Bits Lisp_Bits;
  enum Lisp_Compiled Lisp_Compiled;
  enum maxargs maxargs;
  enum MAX_ALLOCA MAX_ALLOCA;
  enum More_Lisp_Bits More_Lisp_Bits;
  enum pvec_type pvec_type;
  enum defined_HAVE_X_WINDOWS defined_HAVE_X_WINDOWS;
  enum defined_HAVE_PGTK defined_HAVE_PGTK;
} const EXTERNALLY_VISIBLE gdb_make_enums_visible = {0};
#endif	/* __GNUC__ */
