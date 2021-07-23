/* NeXT/Open/GNUstep and macOS Cocoa menu and toolbar module.
   Copyright (C) 2007-2021 Free Software Foundation, Inc.

This file is part of GNU Emacs.

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

/*
By Adrian Robert, based on code from original nsmenu.m (Carl Edman,
Christian Limpach, Scott Bender, Christophe de Dinechin) and code in the
Carbon version by Yamamoto Mitsuharu. */

/* This should be the first include, as it may set up #defines affecting
   interpretation of even the system includes.  */
#include <config.h>

#include "lisp.h"
#include "window.h"
#include "character.h"
#include "buffer.h"
#include "keymap.h"
#include "coding.h"
#include "commands.h"
#include "blockinput.h"
#include "nsterm.h"
#include "termhooks.h"
#include "keyboard.h"
#include "menu.h"
#include "pdumper.h"

#define NSMENUPROFILE 0

#if NSMENUPROFILE
#include <sys/timeb.h>
#include <sys/types.h>
#endif


extern long context_menu_value;
EmacsMenu *svcsMenu;
/* Nonzero means a menu is currently active.  */
static int popup_activated_flag;

/* NOTE: toolbar implementation is at end,
   following complete menu implementation.  */


/* ==========================================================================

    Menu: Externally-called functions

   ========================================================================== */


/* Supposed to discard menubar and free storage.  Since we share the
   menubar among frames and update its context for the focused window,
   we do not discard the menu.  We do, however, want to remove any
   existing menu items.  */
void
free_frame_menubar (struct frame *f)
{
  id menu = [NSApp mainMenu];
  for (int i = [menu numberOfItems] - 1 ; i >= 0; i--)
    {
      NSMenuItem *item = (NSMenuItem *)[menu itemAtIndex:i];
      NSString *title = [item title];

      if ([ns_app_name isEqualToString:title])
        continue;

      [menu removeItemAtIndex:i];
    }
}


int
popup_activated (void)
{
  return popup_activated_flag;
}


/* --------------------------------------------------------------------------
    Update menubar.  Three cases:
    1) ! deep_p, submenu = nil: Fresh switch onto a frame -- either set up
       just top-level menu strings (macOS), or goto case (2) (GNUstep).
    2) deep_p, submenu = nil: Recompute all submenus.
    3) deep_p, submenu = non-nil: Update contents of a single submenu.
   -------------------------------------------------------------------------- */
static void
ns_update_menubar (struct frame *f, bool deep_p)
{
  BOOL needsSet = NO;
  id menu = [NSApp mainMenu];
  bool owfi;

  Lisp_Object items;
  widget_value *wv, *first_wv, *prev_wv = 0;
  int i;
  int *submenu_start, *submenu_end;
  bool *submenu_top_level_items;
  int *submenu_n_panes;

#if NSMENUPROFILE
  struct timeb tb;
  long t;
#endif

  NSTRACE ("ns_update_menubar");

  if (f != SELECTED_FRAME () || FRAME_EXTERNAL_MENU_BAR (f) == 0)
      return;
  XSETFRAME (Vmenu_updating_frame, f);
/*fprintf (stderr, "ns_update_menubar: frame: %p\tdeep: %d\tsub: %p\n", f, deep_p, submenu); */

  block_input ();

  /* Menu may have been created automatically; if so, discard it.  */
  if ([menu isKindOfClass: [EmacsMenu class]] == NO)
    {
      [menu release];
      menu = nil;
    }

  if (menu == nil)
    {
      menu = [[EmacsMenu alloc] initWithTitle: ns_app_name];
      needsSet = YES;
    }

#if NSMENUPROFILE
  ftime (&tb);
  t = -(1000*tb.time+tb.millitm);
#endif

#ifdef NS_IMPL_GNUSTEP
  deep_p = 1; /* See comment in menuNeedsUpdate.  */
#endif

  if (deep_p)
    {
      /* Make a widget-value tree representing the entire menu trees.  */

      struct buffer *prev = current_buffer;
      Lisp_Object buffer;
      ptrdiff_t specpdl_count = SPECPDL_INDEX ();
      int previous_menu_items_used = f->menu_bar_items_used;
      Lisp_Object *previous_items
	= alloca (previous_menu_items_used * sizeof *previous_items);
      int subitems;

      buffer = XWINDOW (FRAME_SELECTED_WINDOW (f))->contents;
      specbind (Qinhibit_quit, Qt);
      /* Don't let the debugger step into this code
	 because it is not reentrant.  */
      specbind (Qdebug_on_next_call, Qnil);

      record_unwind_save_match_data ();
      if (NILP (Voverriding_local_map_menu_flag))
	{
	  specbind (Qoverriding_terminal_local_map, Qnil);
	  specbind (Qoverriding_local_map, Qnil);
	}

      set_buffer_internal_1 (XBUFFER (buffer));

      /* TODO: for some reason this is not needed in other terms, but
	 some menu updates call Info-extract-pointer which causes
	 abort-on-error if waiting-for-input.  Needs further
	 investigation.  */
      owfi = waiting_for_input;
      waiting_for_input = 0;

      /* Run the Lucid hook.  */
      safe_run_hooks (Qactivate_menubar_hook);

      /* If it has changed current-menubar from previous value,
	 really recompute the menubar from the value.  */
      if (! NILP (Vlucid_menu_bar_dirty_flag))
	call0 (Qrecompute_lucid_menubar);
      safe_run_hooks (Qmenu_bar_update_hook);
      fset_menu_bar_items (f, menu_bar_items (FRAME_MENU_BAR_ITEMS (f)));

      items = FRAME_MENU_BAR_ITEMS (f);

      /* Save the frame's previous menu bar contents data.  */
      if (previous_menu_items_used)
	memcpy (previous_items, xvector_contents (f->menu_bar_vector),
		previous_menu_items_used * word_size);

      /* Fill in menu_items with the current menu bar contents.
	 This can evaluate Lisp code.  */
      save_menu_items ();

      menu_items = f->menu_bar_vector;
      menu_items_allocated = VECTORP (menu_items) ? ASIZE (menu_items) : 0;
      subitems = ASIZE (items) / 4;
      submenu_start = alloca ((subitems + 1) * sizeof *submenu_start);
      submenu_end = alloca (subitems * sizeof *submenu_end);
      submenu_n_panes = alloca (subitems * sizeof *submenu_n_panes);
      submenu_top_level_items = alloca (subitems
					* sizeof *submenu_top_level_items);
      init_menu_items ();
      for (i = 0; i < subitems; i++)
	{
	  Lisp_Object key, string, maps;

	  key = AREF (items, 4 * i);
	  string = AREF (items, 4 * i + 1);
	  maps = AREF (items, 4 * i + 2);
	  if (NILP (string))
	    break;

	  submenu_start[i] = menu_items_used;

	  menu_items_n_panes = 0;
	  submenu_top_level_items[i]
	    = parse_single_submenu (key, string, maps);
	  submenu_n_panes[i] = menu_items_n_panes;

	  submenu_end[i] = menu_items_used;
	}

      submenu_start[i] = -1;
      finish_menu_items ();
      waiting_for_input = owfi;

      /* Convert menu_items into widget_value trees
	 to display the menu.  This cannot evaluate Lisp code.  */

      wv = make_widget_value ("menubar", NULL, true, Qnil);
      wv->button_type = BUTTON_TYPE_NONE;
      first_wv = wv;

      for (i = 0; submenu_start[i] >= 0; i++)
	{
	  menu_items_n_panes = submenu_n_panes[i];
	  wv = digest_single_submenu (submenu_start[i], submenu_end[i],
				      submenu_top_level_items[i]);
	  if (prev_wv)
	    prev_wv->next = wv;
	  else
	    first_wv->contents = wv;
	  /* Don't set wv->name here; GC during the loop might relocate it.  */
	  wv->enabled = true;
	  wv->button_type = BUTTON_TYPE_NONE;
	  prev_wv = wv;
	}

      set_buffer_internal_1 (prev);

      /* If there has been no change in the Lisp-level contents
	 of the menu bar, skip redisplaying it.  Just exit.  */

      /* Compare the new menu items with the ones computed last time.  */
      for (i = 0; i < previous_menu_items_used; i++)
	if (menu_items_used == i
	    || (!EQ (previous_items[i], AREF (menu_items, i))))
	  break;
      if (i == menu_items_used && i == previous_menu_items_used && i != 0)
	{
	  /* The menu items have not changed.  Don't bother updating
	     the menus in any form, since it would be a no-op.  */
	  free_menubar_widget_value_tree (first_wv);
	  discard_menu_items ();
	  unbind_to (specpdl_count, Qnil);
	  return;
	}

      /* The menu items are different, so store them in the frame.  */
      fset_menu_bar_vector (f, menu_items);
      f->menu_bar_items_used = menu_items_used;

      /* This undoes save_menu_items.  */
      unbind_to (specpdl_count, Qnil);

      /* Now GC cannot happen during the lifetime of the widget_value,
	 so it's safe to store data from a Lisp_String.  */
      wv = first_wv->contents;
      for (i = 0; i < ASIZE (items); i += 4)
	{
	  Lisp_Object string;
	  string = AREF (items, i + 1);
	  if (NILP (string))
            break;
          wv->name = SSDATA (string);
          update_submenu_strings (wv->contents);
          wv = wv->next;
	}

    }
  else
    {
      /* Make a widget-value tree containing
	 just the top level menu bar strings.  */

      wv = make_widget_value ("menubar", NULL, true, Qnil);
      wv->button_type = BUTTON_TYPE_NONE;
      first_wv = wv;

      items = FRAME_MENU_BAR_ITEMS (f);
      for (i = 0; i < ASIZE (items); i += 4)
	{
	  Lisp_Object string;

	  string = AREF (items, i + 1);
	  if (NILP (string))
	    break;

	  wv = make_widget_value (SSDATA (string), NULL, true, Qnil);
	  wv->button_type = BUTTON_TYPE_NONE;
	  /* This prevents lwlib from assuming this
	     menu item is really supposed to be empty.  */
	  /* The intptr_t cast avoids a warning.
	     This value just has to be different from small integers.  */
	  wv->call_data = (void *) (intptr_t) (-1);

	  if (prev_wv)
	    prev_wv->next = wv;
	  else
	    first_wv->contents = wv;
	  prev_wv = wv;
	}

      /* Forget what we thought we knew about what is in the
	 detailed contents of the menu bar menus.
	 Changing the top level always destroys the contents.  */
      f->menu_bar_items_used = 0;
    }

  /* Now, update the NS menu.  */
  i = 0;

  /* Make sure we skip the "application" menu, which is always the
     first entry in our top-level menu.  */
  if (i < [menu numberOfItems])
    {
      NSString *title = [[menu itemAtIndex:i] title];
      if ([ns_app_name isEqualToString:title])
        i += 1;
    }

  for (wv = first_wv->contents; wv; wv = wv->next)
    {
      EmacsMenu *submenu;

      if (i < [menu numberOfItems])
        {
          NSString *titleStr = [NSString stringWithUTF8String: wv->name];
          NSMenuItem *item = (NSMenuItem *)[menu itemAtIndex:i];
          submenu = (EmacsMenu *)[item submenu];

#ifdef NS_IMPL_GNUSTEP
          [submenu close];
#endif

          [item setTitle:titleStr];
          [submenu setTitle:titleStr];
          [submenu removeAllItems];
        }
      else
        submenu = [menu addSubmenuWithTitle: wv->name];

#ifdef NS_IMPL_COCOA
      if ([[submenu title] isEqualToString:@"Help"])
        [NSApp setHelpMenu:submenu];
#endif

      if (deep_p)
        [submenu fillWithWidgetValue: wv->contents];

      i += 1;
    }

  while (i < [menu numberOfItems])
    {
      /* Remove any extra items.  */
#ifdef NS_IMPL_GNUSTEP
      NSMenuItem *item = (NSMenuItem *)[menu itemAtIndex:i];
      EmacsMenu *submenu = (EmacsMenu *)[item submenu];
      [submenu close];
#endif

      [menu removeItemAtIndex:i];
    }


  free_menubar_widget_value_tree (first_wv);

#if NSMENUPROFILE
  ftime (&tb);
  t += 1000*tb.time+tb.millitm;
  fprintf (stderr, "Menu update took %ld msec.\n", t);
#endif

  /* set main menu */
  if (needsSet)
    [NSApp setMainMenu: menu];

  unblock_input ();

}


/* Main emacs core entry point for menubar menus: called to indicate that the
   frame's menus have changed, and the *step representation should be updated
   from Lisp.  */
void
set_frame_menubar (struct frame *f, bool deep_p)
{
  ns_update_menubar (f, deep_p);
}


/* ==========================================================================

    Menu: class implementation

   ========================================================================== */


/* Menu that can define itself from Emacs "widget_value"s and will lazily
   update itself when user clicked.  Based on Carbon/AppKit implementation
   by Yamamoto Mitsuharu.  */
@implementation EmacsMenu

/* override designated initializer */
- (instancetype)initWithTitle: (NSString *)title
{
  if ((self = [super initWithTitle: title]))
    [self setAutoenablesItems: NO];
  [self setDelegate: self];

  needsUpdate = YES;

  return self;
}


/* Delegate method called when a submenu is being opened: run a 'deep'
   call to ns_update_menubar.  */
- (void)menuNeedsUpdate: (NSMenu *)menu
{
  if (!FRAME_LIVE_P (SELECTED_FRAME ()))
    return;

#ifdef NS_IMPL_COCOA
/* TODO: GNUstep calls this method when the menu is still being built
   which results in a recursive stack overflow.  One possible solution
   is to use menuWillOpen instead, but the Apple docs explicitly warn
   against changing the contents of the menu in it.  I don't know what
   the right thing to do for GNUstep is.  */
  if (needsUpdate)
    ns_update_menubar (SELECTED_FRAME (), true);
#endif
}


- (BOOL)performKeyEquivalent: (NSEvent *)theEvent
{
  if (SELECTED_FRAME () && FRAME_NS_P (SELECTED_FRAME ())
      && FRAME_NS_VIEW (SELECTED_FRAME ()))
    [FRAME_NS_VIEW (SELECTED_FRAME ()) keyDown: theEvent];
  return YES;
}


- (NSMenuItem *)addItemWithWidgetValue: (void *)wvptr
                            attributes: (NSDictionary *)attributes
{
  NSMenuItem *item;
  widget_value *wv = (widget_value *)wvptr;

  if (menu_separator_name_p (wv->name))
    {
      item = (NSMenuItem *)[NSMenuItem separatorItem];
    }
  else
    {
      NSString *title = [NSString stringWithUTF8String: wv->name];
      if (title == nil)
        title = @"< ? >";  /* (get out in the open so we know about it) */

      item = [[[NSMenuItem alloc] init] autorelease];
      if (wv->key)
        {
          NSString *key = [NSString stringWithUTF8String: wv->key];
#ifdef NS_IMPL_COCOA
          /* Cocoa only permits a single key (with modifiers) as
             keyEquivalent, so we put them in the title string
             in a tab-separated column. */
          title = [title stringByAppendingFormat: @"\t%@", key];
#else
          [item setKeyEquivalent: key];
#endif
        }

      NSAttributedString *atitle = [[[NSAttributedString alloc]
                                         initWithString: title
                                             attributes: attributes]
                                     autorelease];
      [item setAction: @selector (menuDown:)];
      [item setAttributedTitle: atitle];
      [item setEnabled: wv->enabled];

      /* Draw radio buttons and tickboxes.  */
      if (wv->selected && (wv->button_type == BUTTON_TYPE_TOGGLE ||
                           wv->button_type == BUTTON_TYPE_RADIO))
        [item setState: NSControlStateValueOn];
      else
        [item setState: NSControlStateValueOff];

      [item setTag: (NSInteger)wv->call_data];
    }

  [self addItem: item];
  return item;
}


/* convenience */
-(void)removeAllItems
{
#ifdef NS_IMPL_COCOA
  [super removeAllItems];
#else
  /* GNUstep doesn't have removeAllItems yet, so do it
     manually.  */
  int n;

  for (n = [self numberOfItems]-1; n >= 0; n--)
    [self removeItemAtIndex: n];
#endif

  needsUpdate = YES;
}

#ifdef NS_IMPL_COCOA
typedef struct {
  const char *from, *to;
} subst_t;

/* Standard keyboard symbols used in menus. */
static const subst_t key_symbols[] = {
  {"<backspace>",  "⌫"},
  {"DEL",          "⌫"},
  {"<deletechar>", "⌦"},
  {"<return>",     "↩"},
  {"RET",          "↩"},
  {"<left>",       "←"},
  {"<right>",      "→"},
  {"<up>",         "↑"},
  {"<down>",       "↓"},
  {"<prior>",      "⇞"},
  {"<next>",       "⇟"},
  {"<home>",       "↖"},
  {"<end>",        "↘"},
  {"<tab>",        "⇥"},
  {"TAB",          "⇥"},
  {"<backtab>",    "⇤"},
};

/* Transform the key sequence KEY into something prettier by
   substituting keyboard symbols. */
static char *
prettify_key (const char *key)
{
  while (*key == ' ') key++;

  int len = strlen (key);
  char *buf = xmalloc (len + 1);
  memcpy (buf, key, len + 1);
  for (int i = 0; i < ARRAYELTS (key_symbols); i++)
    {
      ptrdiff_t fromlen = strlen (key_symbols[i].from);
      char *p = buf;
      while (p < buf + len)
        {
          char *match = memmem (buf, len, key_symbols[i].from, fromlen);
          if (!match)
            break;
          ptrdiff_t tolen = strlen (key_symbols[i].to);
          eassert (tolen <= fromlen);
          memcpy (match, key_symbols[i].to, tolen);
          memmove (match + tolen, match + fromlen,
                   len - (match + fromlen - buf) + 1);
          len -= fromlen - tolen;
          p = match + tolen;
        }
    }
  Lisp_Object result = build_string (buf);
  xfree (buf);
  return SSDATA (result);
}
#endif /* NS_IMPL_COCOA */

- (void)fillWithWidgetValue: (void *)wvptr
{
  widget_value *first_wv = (widget_value *)wvptr;
  NSDictionary *attributes = nil;

#ifdef NS_IMPL_COCOA
  /* Cocoa doesn't allow multi-key sequences in its menu display, so
     work around it by using tabs to split the title into two
     columns.  */
  NSFont *menuFont = [NSFont menuFontOfSize:0];
  NSDictionary *font_attribs = @{NSFontAttributeName: menuFont};
  CGFloat maxNameWidth = 0;
  CGFloat maxKeyWidth = 0;

  /* Determine the maximum width of all menu items. */
  for (widget_value *wv = first_wv; wv != NULL; wv = wv->next)
    if (!menu_separator_name_p (wv->name))
      {
        NSString *name = [NSString stringWithUTF8String: wv->name];
        NSSize nameSize = [name sizeWithAttributes: font_attribs];
        maxNameWidth = MAX(maxNameWidth, nameSize.width);
        if (wv->key)
          {
            wv->key = prettify_key (wv->key);
            NSString *key = [NSString stringWithUTF8String: wv->key];
            NSSize keySize = [key sizeWithAttributes: font_attribs];
            maxKeyWidth = MAX(maxKeyWidth, keySize.width);
          }
      }

  /* Put some space between the names and keys. */
  CGFloat maxWidth = maxNameWidth + maxKeyWidth + 40;

  /* Set a right-aligned tab stop at the maximum width, so that the
     key will appear immediately to the left of it. */
  NSTextTab *tab =
    [[[NSTextTab alloc] initWithTextAlignment: NSTextAlignmentRight
                                     location: maxWidth
                                      options: @{}] autorelease];
  NSMutableParagraphStyle *pstyle = [[[NSMutableParagraphStyle alloc] init]
                                      autorelease];
  [pstyle setTabStops: @[tab]];
  attributes = @{NSParagraphStyleAttributeName: pstyle};
#endif

  /* clear existing contents */
  [self removeAllItems];

  /* add new contents */
  for (widget_value *wv = first_wv; wv != NULL; wv = wv->next)
    {
      NSMenuItem *item = [self addItemWithWidgetValue: wv
                                           attributes: attributes];

      if (wv->contents)
        {
          EmacsMenu *submenu;

          submenu = [[EmacsMenu alloc] initWithTitle: [item title]];

          [self setSubmenu: submenu forItem: item];
          [submenu fillWithWidgetValue: wv->contents];
          [submenu release];
          [item setAction: (SEL)nil];
        }
    }

  needsUpdate = NO;

#ifdef NS_IMPL_GNUSTEP
  if ([[self window] isVisible])
    [self sizeToFit];
#endif
}


/* Adds an empty submenu and returns it.  */
- (EmacsMenu *)addSubmenuWithTitle: (const char *)title
{
  NSString *titleStr = [NSString stringWithUTF8String: title];
  NSMenuItem *item = (NSMenuItem *)[self addItemWithTitle: titleStr
                                                   action: (SEL)nil
                                            keyEquivalent: @""];
  EmacsMenu *submenu = [[EmacsMenu alloc] initWithTitle: titleStr];
  [self setSubmenu: submenu forItem: item];
  [submenu release];
  return submenu;
}

/* Run a menu in popup mode.  */
- (Lisp_Object)runMenuAt: (NSPoint)p forFrame: (struct frame *)f
                 keymaps: (bool)keymaps
{
  EmacsView *view = FRAME_NS_VIEW (f);
  NSEvent *e, *event;
  long retVal;

  /* p = [view convertPoint:p fromView: nil]; */
  p.y = NSHeight ([view frame]) - p.y;
  e = [[view window] currentEvent];
   event = [NSEvent mouseEventWithType: NSEventTypeRightMouseDown
                              location: p
                         modifierFlags: 0
                             timestamp: [e timestamp]
                          windowNumber: [[view window] windowNumber]
                               context: nil
                           eventNumber: 0 /* [e eventNumber] */
                            clickCount: 1
                              pressure: 0];

  context_menu_value = -1;
  [NSMenu popUpContextMenu: self withEvent: event forView: view];
  retVal = context_menu_value;
  context_menu_value = 0;
  return retVal > 0
      ? find_and_return_menu_selection (f, keymaps, (void *)retVal)
      : Qnil;
}

#ifdef NS_IMPL_GNUSTEP
- (void) close
{
    /* Close all the submenus.  This has the unfortunate side-effect of
     breaking tear-off menus, however if we don't do this then we get
     a crash when the menus are removed during updates.  */
  for (int i = 0 ; i < [self numberOfItems] ; i++)
    {
      NSMenuItem *item = [self itemAtIndex:i];
      if ([item hasSubmenu])
        [(EmacsMenu *)[item submenu] close];
    }

  [super close];
}

/* GNUstep seems to have a number of required methods in
   NSMenuDelegate that are optional in Cocoa.  */

- (void) menuWillOpen:(NSMenu *)menu
{
}

- (void) menuDidClose:(NSMenu *)menu
{
}

- (NSRect)confinementRectForMenu:(NSMenu *)menu
                        onScreen:(NSScreen *)screen
{
  return NSZeroRect;
}

- (void)menu:(NSMenu *)menu willHighlightItem:(NSMenuItem *)item
{
}
#endif

@end  /* EmacsMenu */



/* ==========================================================================

    Context Menu: implementing functions

   ========================================================================== */

Lisp_Object
ns_menu_show (struct frame *f, int x, int y, int menuflags,
	      Lisp_Object title, const char **error)
{
  EmacsMenu *pmenu;
  NSPoint p;
  Lisp_Object tem;
  ptrdiff_t specpdl_count = SPECPDL_INDEX ();
  widget_value *wv, *first_wv = 0;
  bool keymaps = (menuflags & MENU_KEYMAPS);

  NSTRACE ("ns_menu_show");

  block_input ();

  p.x = x; p.y = y;

  /* now parse stage 2 as in ns_update_menubar */
  wv = make_widget_value ("contextmenu", NULL, true, Qnil);
  wv->button_type = BUTTON_TYPE_NONE;
  first_wv = wv;

#if 0
  /* FIXME: a couple of one-line differences prevent reuse.  */
  wv = digest_single_submenu (0, menu_items_used, 0);
#else
  {
  widget_value *save_wv = 0, *prev_wv = 0;
  widget_value **submenu_stack
    = alloca (menu_items_used * sizeof *submenu_stack);
  /* Lisp_Object *subprefix_stack
       = alloca (menu_items_used * sizeof *subprefix_stack); */
  int submenu_depth = 0;
  int first_pane = 1;
  int i;

  /* Loop over all panes and items, filling in the tree.  */
  i = 0;
  while (i < menu_items_used)
    {
      if (NILP (AREF (menu_items, i)))
	{
	  submenu_stack[submenu_depth++] = save_wv;
	  save_wv = prev_wv;
	  prev_wv = 0;
	  first_pane = 1;
	  i++;
	}
      else if (EQ (AREF (menu_items, i), Qlambda))
	{
	  prev_wv = save_wv;
	  save_wv = submenu_stack[--submenu_depth];
	  first_pane = 0;
	  i++;
	}
      else if (EQ (AREF (menu_items, i), Qt)
	       && submenu_depth != 0)
	i += MENU_ITEMS_PANE_LENGTH;
      /* Ignore a nil in the item list.
	 It's meaningful only for dialog boxes.  */
      else if (EQ (AREF (menu_items, i), Qquote))
	i += 1;
      else if (EQ (AREF (menu_items, i), Qt))
	{
	  /* Create a new pane.  */
	  Lisp_Object pane_name, prefix;
	  const char *pane_string;

	  pane_name = AREF (menu_items, i + MENU_ITEMS_PANE_NAME);
	  prefix = AREF (menu_items, i + MENU_ITEMS_PANE_PREFIX);

#ifndef HAVE_MULTILINGUAL_MENU
	  if (STRINGP (pane_name) && STRING_MULTIBYTE (pane_name))
	    {
	      pane_name = ENCODE_MENU_STRING (pane_name);
	      ASET (menu_items, i + MENU_ITEMS_PANE_NAME, pane_name);
	    }
#endif
	  pane_string = (NILP (pane_name)
			 ? "" : SSDATA (pane_name));
	  /* If there is just one top-level pane, put all its items directly
	     under the top-level menu.  */
	  if (menu_items_n_panes == 1)
	    pane_string = "";

	  /* If the pane has a meaningful name,
	     make the pane a top-level menu item
	     with its items as a submenu beneath it.  */
	  if (!keymaps && strcmp (pane_string, ""))
	    {
	      wv = make_widget_value (pane_string, NULL, true, Qnil);
	      if (save_wv)
		save_wv->next = wv;
	      else
		first_wv->contents = wv;
	      if (keymaps && !NILP (prefix))
		wv->name++;
	      wv->button_type = BUTTON_TYPE_NONE;
	      save_wv = wv;
	      prev_wv = 0;
	    }
	  else if (first_pane)
	    {
	      save_wv = wv;
	      prev_wv = 0;
	    }
	  first_pane = 0;
	  i += MENU_ITEMS_PANE_LENGTH;
	}
      else
	{
	  /* Create a new item within current pane.  */
	  Lisp_Object item_name, enable, descrip, def, type, selected, help;
	  item_name = AREF (menu_items, i + MENU_ITEMS_ITEM_NAME);
	  enable = AREF (menu_items, i + MENU_ITEMS_ITEM_ENABLE);
	  descrip = AREF (menu_items, i + MENU_ITEMS_ITEM_EQUIV_KEY);
	  def = AREF (menu_items, i + MENU_ITEMS_ITEM_DEFINITION);
	  type = AREF (menu_items, i + MENU_ITEMS_ITEM_TYPE);
	  selected = AREF (menu_items, i + MENU_ITEMS_ITEM_SELECTED);
	  help = AREF (menu_items, i + MENU_ITEMS_ITEM_HELP);

#ifndef HAVE_MULTILINGUAL_MENU
          if (STRINGP (item_name) && STRING_MULTIBYTE (item_name))
	    {
	      item_name = ENCODE_MENU_STRING (item_name);
	      ASET (menu_items, i + MENU_ITEMS_ITEM_NAME, item_name);
	    }

          if (STRINGP (descrip) && STRING_MULTIBYTE (descrip))
	    {
	      descrip = ENCODE_MENU_STRING (descrip);
	      ASET (menu_items, i + MENU_ITEMS_ITEM_EQUIV_KEY, descrip);
	    }
#endif /* not HAVE_MULTILINGUAL_MENU */

	  wv = make_widget_value (SSDATA (item_name), NULL, !NILP (enable),
				  STRINGP (help) ? help : Qnil);
	  if (prev_wv)
	    prev_wv->next = wv;
	  else
	    save_wv->contents = wv;
	  if (!NILP (descrip))
	    wv->key = SSDATA (descrip);
	  /* If this item has a null value,
	     make the call_data null so that it won't display a box
	     when the mouse is on it.  */
	  wv->call_data = !NILP (def) ? aref_addr (menu_items, i) : 0;

	  if (NILP (type))
	    wv->button_type = BUTTON_TYPE_NONE;
	  else if (EQ (type, QCtoggle))
	    wv->button_type = BUTTON_TYPE_TOGGLE;
	  else if (EQ (type, QCradio))
	    wv->button_type = BUTTON_TYPE_RADIO;
	  else
	    emacs_abort ();

	  wv->selected = !NILP (selected);

	  prev_wv = wv;

	  i += MENU_ITEMS_ITEM_LENGTH;
	}
    }
  }
#endif

  if (!NILP (title))
    {
      widget_value *wv_title;
      widget_value *wv_sep = make_widget_value ("--", NULL, false, Qnil);

      /* Maybe replace this separator with a bitmap or owner-draw item
	 so that it looks better.  Having two separators looks odd.  */
      wv_sep->next = first_wv->contents;

#ifndef HAVE_MULTILINGUAL_MENU
      if (STRING_MULTIBYTE (title))
	title = ENCODE_MENU_STRING (title);
#endif
      wv_title = make_widget_value (SSDATA (title), NULL, false, Qnil);
      wv_title->button_type = BUTTON_TYPE_NONE;
      wv_title->next = wv_sep;
      first_wv->contents = wv_title;
    }

  pmenu = [[EmacsMenu alloc] initWithTitle:
                               [NSString stringWithLispString: title]];
  [pmenu fillWithWidgetValue: first_wv->contents];
  free_menubar_widget_value_tree (first_wv);
  unbind_to (specpdl_count, Qnil);

  popup_activated_flag = 1;
  tem = [pmenu runMenuAt: p forFrame: f keymaps: keymaps];
  popup_activated_flag = 0;
  [[FRAME_NS_VIEW (SELECTED_FRAME ()) window] makeKeyWindow];

  unblock_input ();
  return tem;
}


/* ==========================================================================

    Toolbar: externally-called functions

   ========================================================================== */

void
free_frame_tool_bar (struct frame *f)
/* --------------------------------------------------------------------------
    Under NS we just hide the toolbar until it might be needed again.
   -------------------------------------------------------------------------- */
{
  EmacsView *view = FRAME_NS_VIEW (f);

  NSTRACE ("free_frame_tool_bar");

  block_input ();
  view->wait_for_tool_bar = NO;

  /* Note: This triggers an animation, which calls windowDidResize
     repeatedly.  */
  f->output_data.ns->in_animation = 1;
  [[view toolbar] setVisible: NO];
  f->output_data.ns->in_animation = 0;

  unblock_input ();
}

void
update_frame_tool_bar (struct frame *f)
/* --------------------------------------------------------------------------
    Update toolbar contents.
   -------------------------------------------------------------------------- */
{
  int i, k = 0;
  EmacsView *view = FRAME_NS_VIEW (f);
  EmacsToolbar *toolbar = [view toolbar];

  NSTRACE ("update_frame_tool_bar");

  if (view == nil || toolbar == nil) return;
  block_input ();

#ifdef NS_IMPL_COCOA
  [toolbar clearActive];
#else
  [toolbar clearAll];
#endif

  /* Update EmacsToolbar as in GtkUtils, build items list.  */
  for (i = 0; i < f->n_tool_bar_items; ++i)
    {
#define TOOLPROP(IDX) AREF (f->tool_bar_items, \
                            i * TOOL_BAR_ITEM_NSLOTS + (IDX))

      BOOL enabled_p = !NILP (TOOLPROP (TOOL_BAR_ITEM_ENABLED_P));
      int idx;
      ptrdiff_t img_id;
      struct image *img;
      Lisp_Object image;
      Lisp_Object helpObj;
      const char *helpText;

      /* Check if this is a separator.  */
      if (EQ (TOOLPROP (TOOL_BAR_ITEM_TYPE), Qt))
        {
          /* Skip separators.  Newer macOS don't show them, and on
             GNUstep they are wide as a button, thus overflowing the
             toolbar most of the time.  */
          continue;
        }

      /* If image is a vector, choose the image according to the
	 button state.  */
      image = TOOLPROP (TOOL_BAR_ITEM_IMAGES);
      if (VECTORP (image))
	{
          /* NS toolbar auto-computes disabled and selected images.  */
          idx = TOOL_BAR_IMAGE_ENABLED_SELECTED;
	  eassert (ASIZE (image) >= idx);
	  image = AREF (image, idx);
	}
      else
        {
          idx = -1;
        }
      helpObj = TOOLPROP (TOOL_BAR_ITEM_HELP);
      if (NILP (helpObj))
        helpObj = TOOLPROP (TOOL_BAR_ITEM_CAPTION);
      helpText = NILP (helpObj) ? "" : SSDATA (helpObj);

      /* Ignore invalid image specifications.  */
      if (!valid_image_p (image))
        {
          /* Don't log anything, GNUS makes invalid images all the time.  */
          continue;
        }

      img_id = lookup_image (f, image, -1);
      img = IMAGE_FROM_ID (f, img_id);
      prepare_image_for_display (f, img);

      if (img->load_failed_p || img->pixmap == nil)
        {
          NSLog (@"Could not prepare toolbar image for display.");
          continue;
        }

      [toolbar addDisplayItemWithImage: img->pixmap
                                   idx: k++
                                   tag: i
                              helpText: helpText
                               enabled: enabled_p];
#undef TOOLPROP
    }

  if (![toolbar isVisible])
    {
      f->output_data.ns->in_animation = 1;
      [toolbar setVisible: YES];
      f->output_data.ns->in_animation = 0;
    }

#ifdef NS_IMPL_COCOA
  if ([toolbar changed])
    {
      /* Inform app that toolbar has changed.  */
      NSDictionary *dict = [toolbar configurationDictionary];
      NSMutableDictionary *newDict = [dict mutableCopy];
      NSEnumerator *keys = [[dict allKeys] objectEnumerator];
      id key;
      while ((key = [keys nextObject]) != nil)
        {
          NSObject *val = [dict objectForKey: key];
          if ([val isKindOfClass: [NSArray class]])
            {
              [newDict setObject:
                         [toolbar toolbarDefaultItemIdentifiers: toolbar]
                          forKey: key];
              break;
            }
        }
      [toolbar setConfigurationFromDictionary: newDict];
      [newDict release];
    }
#endif

  if (view->wait_for_tool_bar && FRAME_TOOLBAR_HEIGHT (f) > 0)
    {
      view->wait_for_tool_bar = NO;
      [view setNeedsDisplay: YES];
    }

  unblock_input ();
}


/* ==========================================================================

    Toolbar: class implementation

   ========================================================================== */

@implementation EmacsToolbar

- (instancetype)initForView: (EmacsView *)view withIdentifier: (NSString *)identifier
{
  NSTRACE ("[EmacsToolbar initForView: withIdentifier:]");

  self = [super initWithIdentifier: identifier];
  emacsView = view;
  [self setDisplayMode: NSToolbarDisplayModeIconOnly];
  [self setSizeMode: NSToolbarSizeModeSmall];
  [self setDelegate: self];
  identifierToItem = [[NSMutableDictionary alloc] initWithCapacity: 10];
  activeIdentifiers = [[NSMutableArray alloc] initWithCapacity: 8];
  prevIdentifiers = nil;
  prevEnablement = enablement = 0L;
  return self;
}

- (void)dealloc
{
  NSTRACE ("[EmacsToolbar dealloc]");

  [prevIdentifiers release];
  [activeIdentifiers release];
  [identifierToItem release];
  [super dealloc];
}

- (void) clearActive
{
  NSTRACE ("[EmacsToolbar clearActive]");

  [prevIdentifiers release];
  prevIdentifiers = [activeIdentifiers copy];
  [activeIdentifiers removeAllObjects];
  prevEnablement = enablement;
  enablement = 0L;
}

- (void) clearAll
{
  NSTRACE ("[EmacsToolbar clearAll]");

  [self clearActive];
  while ([[self items] count] > 0)
    [self removeItemAtIndex: 0];
}

- (BOOL) changed
{
  NSTRACE ("[EmacsToolbar changed]");

  return [activeIdentifiers isEqualToArray: prevIdentifiers] &&
    enablement == prevEnablement ? NO : YES;
}

- (void) addDisplayItemWithImage: (EmacsImage *)img
                             idx: (int)idx
                             tag: (int)tag
                        helpText: (const char *)help
                         enabled: (BOOL)enabled
{
  NSTRACE ("[EmacsToolbar addDisplayItemWithImage: ...]");

  /* 1) come up w/identifier */
  NSString *identifier
    = [NSString stringWithFormat: @"%lu", (unsigned long)[img hash]];
  [activeIdentifiers addObject: identifier];

  /* 2) create / reuse item */
  NSToolbarItem *item = [identifierToItem objectForKey: identifier];
  if (item == nil)
    {
      item = [[[NSToolbarItem alloc] initWithItemIdentifier: identifier]
               autorelease];
      [item setImage: img];
      [item setToolTip: [NSString stringWithUTF8String: help]];
      [item setTarget: emacsView];
      [item setAction: @selector (toolbarClicked:)];
      [identifierToItem setObject: item forKey: identifier];
    }

#ifdef NS_IMPL_GNUSTEP
  [self insertItemWithItemIdentifier: identifier atIndex: idx];
#endif

  [item setTag: tag];
  [item setEnabled: enabled];

  /* 3) update state */
  enablement = (enablement << 1) | (enabled == YES);
}

/* This overrides super's implementation, which automatically sets
   all items to enabled state (for some reason).  */
- (void)validateVisibleItems
{
  NSTRACE ("[EmacsToolbar validateVisibleItems]");
}


/* delegate methods */

- (NSToolbarItem *)toolbar: (NSToolbar *)toolbar
      itemForItemIdentifier: (NSString *)itemIdentifier
  willBeInsertedIntoToolbar: (BOOL)flag
{
  NSTRACE ("[EmacsToolbar toolbar: ...]");

  /* Look up NSToolbarItem by identifier and return...  */
  return [identifierToItem objectForKey: itemIdentifier];
}

- (NSArray *)toolbarDefaultItemIdentifiers: (NSToolbar *)toolbar
{
  NSTRACE ("[EmacsToolbar toolbarDefaultItemIdentifiers:]");

  /* Return entire set.  */
  return activeIdentifiers;
}

/* for configuration palette (not yet supported) */
- (NSArray *)toolbarAllowedItemIdentifiers: (NSToolbar *)toolbar
{
  NSTRACE ("[EmacsToolbar toolbarAllowedItemIdentifiers:]");

  /* return entire set...  */
  return activeIdentifiers;
  //return [identifierToItem allKeys];
}

- (void)setVisible:(BOOL)shown
{
  NSTRACE ("[EmacsToolbar setVisible:%d]", shown);

  [super setVisible:shown];
}


/* optional and unneeded */
/* - toolbarWillAddItem: (NSNotification *)notification { } */
/* - toolbarDidRemoveItem: (NSNotification *)notification { } */
/* - (NSArray *)toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar */

@end  /* EmacsToolbar */



/* ==========================================================================

    Tooltip: class implementation

   ========================================================================== */

/* Needed because NeXTstep does not provide enough control over tooltip
   display.  */
@implementation EmacsTooltip

- (instancetype)init
{
  NSColor *col = [NSColor colorWithCalibratedRed: 1.0 green: 1.0
                                            blue: 0.792 alpha: 0.95];
  NSFont *font = [NSFont toolTipsFontOfSize: 0];
  NSFont *sfont = [font screenFont];
  int height = [sfont ascender] - [sfont descender];
  /* [font boundingRectForFont].size.height; */
  NSRect r = NSMakeRect (0, 0, 100, height+6);

  textField = [[NSTextField alloc] initWithFrame: r];
  [textField setFont: font];
  [textField setBackgroundColor: col];

  [textField setEditable: NO];
  [textField setSelectable: NO];
  [textField setBordered: NO];
  [textField setBezeled: NO];
  [textField setDrawsBackground: YES];

  win = [[NSWindow alloc]
            initWithContentRect: [textField frame]
                      styleMask: 0
                        backing: NSBackingStoreBuffered
                          defer: YES];
  [win setHasShadow: YES];
  [win setReleasedWhenClosed: NO];
  [win setDelegate: self];
  [[win contentView] addSubview: textField];
  /* [win setBackgroundColor: col]; */
  [win setOpaque: NO];

  return self;
}

- (void) dealloc
{
  [win close];
  [win release];
  [textField release];
  [super dealloc];
}

- (void) setText: (char *)text
{
  NSString *str = [NSString stringWithUTF8String: text];
  NSRect r  = [textField frame];
  NSSize tooltipDims;

  [textField setStringValue: str];
  tooltipDims = [[textField cell] cellSize];

  r.size.width = tooltipDims.width;
  r.size.height = tooltipDims.height;
  [textField setFrame: r];
}

- (void) setBackgroundColor: (NSColor *)col
{
  [textField setBackgroundColor: col];
}

- (void) setForegroundColor: (NSColor *)col
{
  [textField setTextColor: col];
}

- (void) showAtX: (int)x Y: (int)y for: (int)seconds
{
  NSRect wr = [win frame];

  wr.origin = NSMakePoint (x, y);
  wr.size = [textField frame].size;

  [win setFrame: wr display: YES];
  [win setLevel: NSPopUpMenuWindowLevel];
  [win orderFront: self];
  [win display];
  timer = [NSTimer scheduledTimerWithTimeInterval: (float)seconds target: self
                                         selector: @selector (hide)
                                         userInfo: nil repeats: NO];
  [timer retain];
}

- (void) hide
{
  [win close];
  if (timer != nil)
    {
      if ([timer isValid])
        [timer invalidate];
      [timer release];
      timer = nil;
    }
}

- (BOOL) isActive
{
  return timer != nil;
}

- (NSRect) frame
{
  return [textField frame];
}

@end  /* EmacsTooltip */



/* ==========================================================================

    Popup Dialog: implementing functions

   ========================================================================== */

static void
pop_down_menu (void *arg)
{
  EmacsDialogPanel *panel = arg;

  if (popup_activated_flag)
    {
      block_input ();
      popup_activated_flag = 0;
      [panel close];
      [[FRAME_NS_VIEW (SELECTED_FRAME ()) window] makeKeyWindow];
      unblock_input ();
    }
}


Lisp_Object
ns_popup_dialog (struct frame *f, Lisp_Object header, Lisp_Object contents)
{
  id dialog;
  Lisp_Object tem, title;
  NSPoint p;
  BOOL isQ;

  NSTRACE ("ns_popup_dialog");

  isQ = NILP (header);

  check_window_system (f);

  p.x = (int)f->left_pos + ((int)FRAME_COLUMN_WIDTH (f) * f->text_cols)/2;
  p.y = (int)f->top_pos + (FRAME_LINE_HEIGHT (f) * f->text_lines)/2;

  title = Fcar (contents);
  CHECK_STRING (title);

  if (NILP (Fcar (Fcdr (contents))))
    /* No buttons specified, add an "Ok" button so users can pop down
       the dialog.  */
    contents = list2 (title, Fcons (build_string ("Ok"), Qt));

  block_input ();
  dialog = [[EmacsDialogPanel alloc] initFromContents: contents
                                           isQuestion: isQ];

  {
    ptrdiff_t specpdl_count = SPECPDL_INDEX ();

    record_unwind_protect_ptr (pop_down_menu, dialog);
    popup_activated_flag = 1;
    tem = [dialog runDialogAt: p];
    unbind_to (specpdl_count, Qnil);  /* calls pop_down_menu */
  }

  unblock_input ();

  return tem;
}


/* ==========================================================================

    Popup Dialog: class implementation

   ========================================================================== */

@interface FlippedView : NSView
{
}
@end

@implementation FlippedView
- (BOOL)isFlipped
{
  return YES;
}
@end

@implementation EmacsDialogPanel

#define SPACER		8.0
#define ICONSIZE	64.0
#define TEXTHEIGHT	20.0
#define MINCELLWIDTH	90.0

- (instancetype)initWithContentRect: (NSRect)contentRect styleMask: (NSWindowStyleMask)aStyle
              backing: (NSBackingStoreType)backingType defer: (BOOL)flag
{
  NSSize spacing = {SPACER, SPACER};
  NSRect area;
  id cell;
  NSImageView *imgView;
  FlippedView *contentView;
  NSImage *img;

  dialog_return   = Qundefined;
  button_values   = NULL;
  area.origin.x   = 3*SPACER;
  area.origin.y   = 2*SPACER;
  area.size.width = ICONSIZE;
  area.size.height= ICONSIZE;
  img = [[NSImage imageNamed: @"NSApplicationIcon"] copy];
  [img setSize: NSMakeSize (ICONSIZE, ICONSIZE)];
  imgView = [[NSImageView alloc] initWithFrame: area];
  [imgView setImage: img];
  [imgView setEditable: NO];
  [img autorelease];
  [imgView autorelease];

  aStyle = NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskUtilityWindow;
  flag = YES;
  rows = 0;
  cols = 1;
  [super initWithContentRect: contentRect styleMask: aStyle
                     backing: backingType defer: flag];
  contentView = [[FlippedView alloc] initWithFrame: [[self contentView] frame]];
  [contentView autorelease];

  [self setContentView: contentView];

  [[self contentView] setAutoresizesSubviews: YES];

  [[self contentView] addSubview: imgView];
  [self setTitle: @""];

  area.origin.x   += ICONSIZE+2*SPACER;
  /* area.origin.y   = TEXTHEIGHT; ICONSIZE/2-10+SPACER; */
  area.size.width = 400;
  area.size.height= TEXTHEIGHT;
  command = [[[NSTextField alloc] initWithFrame: area] autorelease];
  [[self contentView] addSubview: command];
  [command setStringValue: ns_app_name];
  [command setDrawsBackground: NO];
  [command setBezeled: NO];
  [command setSelectable: NO];
  [command setFont: [NSFont boldSystemFontOfSize: 13.0]];

  /* area.origin.x = ICONSIZE+2*SPACER;
  area.origin.y   = TEXTHEIGHT + 2*SPACER;
  area.size.width = 400;
  area.size.height= 2;
  tem = [[[NSBox alloc] initWithFrame: area] autorelease];
  [[self contentView] addSubview: tem];
  [tem setTitlePosition: NSNoTitle];
  [tem setAutoresizingMask: NSViewWidthSizable]; */

  /* area.origin.x = ICONSIZE+2*SPACER; */
  area.origin.y += TEXTHEIGHT+SPACER;
  area.size.width = 400;
  area.size.height= TEXTHEIGHT;
  title = [[[NSTextField alloc] initWithFrame: area] autorelease];
  [[self contentView] addSubview: title];
  [title setDrawsBackground: NO];
  [title setBezeled: NO];
  [title setSelectable: NO];
  [title setFont: [NSFont systemFontOfSize: 11.0]];

  cell = [[[NSButtonCell alloc] initTextCell: @""] autorelease];
  [cell setBordered: NO];
  [cell setEnabled: NO];
  [cell setCellAttribute: NSCellIsInsetButton to: 8];
  [cell setBezelStyle: NSBezelStyleRounded];

  matrix = [[NSMatrix alloc] initWithFrame: contentRect
                                      mode: NSHighlightModeMatrix
                                 prototype: cell
                              numberOfRows: 0
                           numberOfColumns: 1];
  [matrix setFrameOrigin: NSMakePoint (area.origin.x,
                                      area.origin.y + (TEXTHEIGHT+3*SPACER))];
  [matrix setIntercellSpacing: spacing];
  [matrix autorelease];

  [[self contentView] addSubview: matrix];
  [self setReleasedWhenClosed: YES];
  [self setHidesOnDeactivate: YES];
  return self;
}


- (BOOL)windowShouldClose: (id)sender
{
  window_closed = YES;
  [NSApp stop:self];
  return NO;
}

- (void)dealloc
{
  xfree (button_values);
  [super dealloc];
}

- (void)process_dialog: (Lisp_Object) list
{
  Lisp_Object item, lst = list;
  int row = 0;
  int buttons = 0, btnnr = 0;

  for (; CONSP (lst); lst = XCDR (lst))
    {
      item = XCAR (list);
      if (CONSP (item))
        ++buttons;
    }

  if (buttons > 0)
    button_values = xmalloc (buttons * sizeof *button_values);

  for (; CONSP (list); list = XCDR (list))
    {
      item = XCAR (list);
      if (STRINGP (item))
        {
          [self addString: SSDATA (item) row: row++];
        }
      else if (CONSP (item))
        {
          button_values[btnnr] = XCDR (item);
          [self addButton: SSDATA (XCAR (item)) value: btnnr row: row++];
          ++btnnr;
        }
      else if (NILP (item))
        {
          [self addSplit];
          row = 0;
        }
    }
}


- (void)addButton: (char *)str value: (int)tag row: (int)row
{
  id cell;

  if (row >= rows)
    {
      [matrix addRow];
      rows++;
    }
  cell = [matrix cellAtRow: row column: cols-1];
  [cell setTarget: self];
  [cell setAction: @selector (clicked: )];
  [cell setTitle: [NSString stringWithUTF8String: str]];
  [cell setTag: tag];
  [cell setBordered: YES];
  [cell setEnabled: YES];
}


- (void)addString: (char *)str row: (int)row
{
  id cell;

  if (row >= rows)
    {
      [matrix addRow];
      rows++;
    }
  cell = [matrix cellAtRow: row column: cols-1];
  [cell setTitle: [NSString stringWithUTF8String: str]];
  [cell setBordered: YES];
  [cell setEnabled: NO];
}


- (void)addSplit
{
  [matrix addColumn];
  cols++;
}


- (void)clicked: sender
{
  NSArray *sellist = nil;
  EMACS_INT seltag;

  sellist = [sender selectedCells];
  if ([sellist count] < 1)
    return;

  seltag = [[sellist objectAtIndex: 0] tag];
  dialog_return = button_values[seltag];
  [NSApp stop:self];
}


- (instancetype)initFromContents: (Lisp_Object)contents isQuestion: (BOOL)isQ
{
  Lisp_Object head;
  [super init];

  if (CONSP (contents))
    {
      head = Fcar (contents);
      [self process_dialog: Fcdr (contents)];
    }
  else
    head = contents;

  if (STRINGP (head))
      [title setStringValue:
                 [NSString stringWithUTF8String: SSDATA (head)]];
  else if (isQ == YES)
      [title setStringValue: @"Question"];
  else
      [title setStringValue: @"Information"];

  {
    int i;
    NSRect r, s, t;

    if (cols == 1 && rows > 1)	/* Never told where to split.  */
      {
        [matrix addColumn];
        for (i = 0; i < rows/2; i++)
          {
            [matrix putCell: [matrix cellAtRow: (rows+1)/2 column: 0]
                      atRow: i column: 1];
            [matrix removeRow: (rows+1)/2];
          }
      }

    [matrix sizeToFit];
    {
      NSSize csize = [matrix cellSize];
      if (csize.width < MINCELLWIDTH)
        {
          csize.width = MINCELLWIDTH;
          [matrix setCellSize: csize];
          [matrix sizeToCells];
        }
    }

    [title sizeToFit];
    [command sizeToFit];

    t = [matrix frame];
    r = [title frame];
    if (r.size.width+r.origin.x > t.size.width+t.origin.x)
      {
        t.origin.x   = r.origin.x;
        t.size.width = r.size.width;
      }
    r = [command frame];
    if (r.size.width+r.origin.x > t.size.width+t.origin.x)
      {
        t.origin.x   = r.origin.x;
        t.size.width = r.size.width;
      }

    r = [self frame];
    s = [(NSView *)[self contentView] frame];
    r.size.width  += t.origin.x+t.size.width +2*SPACER-s.size.width;
    r.size.height += t.origin.y+t.size.height+SPACER-s.size.height;
    [self setFrame: r display: NO];
  }

  return self;
}



- (void)timeout_handler: (NSTimer *)timedEntry
{
  NSEvent *nxev = [NSEvent otherEventWithType: NSEventTypeApplicationDefined
                            location: NSMakePoint (0, 0)
                       modifierFlags: 0
                           timestamp: 0
                        windowNumber: [[NSApp mainWindow] windowNumber]
                             context: [NSApp context]
                             subtype: 0
                               data1: 0
                               data2: 0];

  timer_fired = YES;
  /* We use stop because stopModal/abortModal out of the main loop
     does not seem to work in 10.6.  But as we use stop we must send a
     real event so the stop is seen and acted upon.  */
  [NSApp stop:self];
  [NSApp postEvent: nxev atStart: NO];
}

- (Lisp_Object)runDialogAt: (NSPoint)p
{
  Lisp_Object ret = Qundefined;

  while (popup_activated_flag)
    {
      NSTimer *tmo = nil;
      struct timespec next_time = timer_check ();

      if (timespec_valid_p (next_time))
        {
          double time = timespectod (next_time);
          tmo = [NSTimer timerWithTimeInterval: time
                                        target: self
                                      selector: @selector (timeout_handler:)
                                      userInfo: 0
                                       repeats: NO];
          [[NSRunLoop currentRunLoop] addTimer: tmo
                                       forMode: NSModalPanelRunLoopMode];
        }
      timer_fired = NO;
      dialog_return = Qundefined;
      [NSApp runModalForWindow: self];
      ret = dialog_return;
      if (! timer_fired)
        {
          if (tmo != nil) [tmo invalidate]; /* Cancels timer.  */
          break;
        }
    }

  if (EQ (ret, Qundefined) && window_closed)
    /* Make close button pressed equivalent to C-g.  */
    quit ();

  return ret;
}

@end


/* ==========================================================================

    Lisp definitions

   ========================================================================== */

DEFUN ("ns-reset-menu", Fns_reset_menu, Sns_reset_menu, 0, 0, 0,
       doc: /* Cause the NS menu to be re-calculated.  */)
     (void)
{
  set_frame_menubar (SELECTED_FRAME (), 0);
  return Qnil;
}


DEFUN ("menu-or-popup-active-p", Fmenu_or_popup_active_p, Smenu_or_popup_active_p, 0, 0, 0,
       doc: /* SKIP: real doc in xmenu.c.  */)
     (void)
{
  return popup_activated () ? Qt : Qnil;
}

/* ==========================================================================

    Lisp interface declaration

   ========================================================================== */

void
syms_of_nsmenu (void)
{
  defsubr (&Sns_reset_menu);
  defsubr (&Smenu_or_popup_active_p);

  DEFSYM (Qdebug_on_next_call, "debug-on-next-call");
}