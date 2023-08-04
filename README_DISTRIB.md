# Junk

Thanks for downloading Junk! If you're a tinkerer, the source code for Junk is available on Github: https://github.com/y2bd/junk

# Keymap

By default, Junk uses the following control scheme

**Left**: Move left  
**Right**: Move right  
**Up**: Hard drop  
**Down**: Soft drop  
**Z**: Rotate counterclockwise  
**X**: Rotate clockwise  

If you wish to change the control scheme

1. Play the game at least once
2. Navigate to the application data folder for Junk
   1. If you're on Windows, this is usually located at `%APPDATA%\Junk`, or `%APPDATA%\LOVE\Junk` if running from source
   2. If you're on MacOS or Linux, find the paths here: https://love2d.org/wiki/love.filesystem
3. Open up `keymap.data`` in your text editor. If it doesn't exist, make sure you've run the game at least once.

`keymap.data` is sorted in the following order:

```
move-left,move-right,hard-drop,soft-drop,rotate-ccw,rotate-cw
```

To change the keymap, swap the default values with new values according to LOVE's KeyConstants table: https://love2d.org/wiki/KeyConstant. Here are some example keymappings:

```
-- standard keymapping
left,right,up,down,z,x

-- left-handed keymapping
a,d,w,s,j,k

-- up-to-rotate keymapping
left,right,space,down,z,up
```