Haxe 3D Engine
=========

A lightweight 3D Engine for Haxe.

Cross-platform Engine
-------------

h3d supports flash and openfl enabled target va GL (js is untested). This is the motion-twin branch, it has diverged from original but we plan to backmerge.

Among improvements : 
hw morph animations
better cpp memory access
improved 2d with bounds, skew, full TRS spriteBatch and filters.

This engine requires openfl to build & run feel free to contact us if need be !

In order to setup the engine, you can do :

> var engine = new h3d.Engine();
> engine.onReady = startMyApp;
> engine.init();

Then in your render loop you can do :

> engine.begin();
> ... render objects ...
> engine.end()

Objects can be created using a combination of a `h3d.mat.Material` (shader and blendmode) and `h3d.prim.Primitive` (geometry).

You can look at available examples in `samples` directory. The real_world example should give you every bit of hints you need.

2D GPU Engine
-------------

The `h2d` package contains classes that provides a complete 2D API that is built on top of `h3d`, and is then GPU accelerated.

It contains an object hierarchy which base class is `h2d.Sprite` and root is `h2d.Scene`


Licence
--------------
This whole code is licensed to it's contributors, namely

Nicolas Cannasse for Motion Twin and Shiro Games

David Elahee for Motion Twin

The Motion Twin Team

The Shiro Games Team

The other contributors

The Headbang Club

under the MIT License.

Copyright (c) 2017-20XX The Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
