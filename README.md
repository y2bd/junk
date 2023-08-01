# Junk

## Game

The more you have, the worse it is for other people.

Junk is a variation of the familiar falling-blocks puzzle game. When you start a game of Junk, you don’t play on an empty board. Instead, you play on the finishing board of someone else’s game. And when you’re done, any mistakes you make, all junk you collect, will become another's problem in due time, for all time.

Junk requires an internet connection to play.

https://y2bd.itch.io/junk
https://ldjam.com/events/ludum-dare/40/junk

## Tech

Junk is a [LÖVE 11.x](https://love2d.org/) game. To "build from source", follow the official instructions on installing and running LÖVE games: https://love2d.org/wiki/Getting_Started

Junk requires an active server hosting the [junk-back](https://github.com/y2bd/junk-back) (or compatible) web service to function. By default, Junk targets my own server (be kind). If you want to use your own server with Junk, change the configuration in [net.lua](./net.lua).