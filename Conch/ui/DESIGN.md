Created: 2018-05-13

Updated: 2018-05-13

---

Conch UI Design Document
========================

This document is intended to capture communicate design decisions related to
the Conch UI. It should be updated whenever new decisions impacting the design
are implemented.


Technical Decisions
--------------------

* [Yarn](https://yarnpkg.com): Dependency management and build tool. Yarn has
  been far less problematic than npm in prior experience. The yarn.lock file
  works well and 
* [ES6 Syntax](https://es6-features.org): The ES6 standard syntax of JavaScript
  is used and prefered in this project. ES6 provides several syntatic
  improvements and eliminates the need for module libraries like RequireJS. As
  not all browsers support ES6 syntax, the source is transpiled with
  [Babel](http://babeljs.io) before distribution.
* [Mithril.js](https://mithril.js.org): Single-Page Application (SPA)
  JavaScript framework. Mithril is much more minimal than other more popular
  SPA frameworks, like React, Ember, and Angular. While this means there's
  little to none in the way of "plugins" to bolt in features, this minimalism
  is a strength in that it's simply JavaScript with little in the way of
  'magic'. Some of the concepts might be unfamiliar to some used to
  manipulating the DOM with jQuery. Going through the helpful [Mithril
  tutorial](https://mithril.js.org/simple-application.html) and some [quick
  screencasts](https://scrimba.com/playlist/playlist-34) will help bring you up
  to speed.
* [Pure CSS](https://purecss.io): Lightweight CSS library. This library was
  chosen early on, but may be too minimal for our needs. Replacement with a
  more comprehensive CSS library like [Bulma](https://bulma.io) or Bootstrap is
  likely.

