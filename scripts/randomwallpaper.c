// clang -lX11 -lXinerama randomwallpaper.c -o ~/.local/bin/randomwallpaper
// this script updates the desktop wallpapers using the nitrogen tool to random
// wallpapers on all displays.
#include <X11/Xlib.h>
#include <X11/extensions/Xinerama.h>
#include <stdio.h>
#include <stdlib.h>

void update_wallpapers(Display *d);

int main(int argc, char *argv[]) {
  Display *d = XOpenDisplay(NULL);

  if (d) {
    int dummy1, dummy2;

    // check if xinerama is supported and enabled
    if (XineramaQueryExtension(d, &dummy1, &dummy2) && XineramaIsActive(d)) {
      update_wallpapers(d);
    } else {
      puts("No Xinerama!\n");
      XCloseDisplay(d);
      return 1;
    }

    XCloseDisplay(d);
    return 0;
  } else {
    puts("Couldn't open display!\n");
    // I return with 0 here, as I don't really wanna see it as an error if this
    // script is run without an X server running.
    return 0;
  }
}

void update_wallpapers(Display *d) {
  int heads = 0;
  XineramaScreenInfo *info = XineramaQueryScreens(d, &heads);

  if (heads > 0) {
    for (int i = 0; i < heads; i++) {
      // works as long as the user doesn't have over 999 monitors :P
      char command[42];
      sprintf(command, "nitrogen --random --set-scaled --head=%d", i);
      printf("Setting wallpaper for screen %d with size %dx%d\n", i,
             info[i].width, info[i].height);
      system(command);
    }
  }

  XFree(info);
}
