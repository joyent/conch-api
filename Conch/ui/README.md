# Conch UI

This directory contains source for the Conch front-end UI. 

See the [Design Document](./DESIGN.md) for information regarding UI design and
development decisions.

## Run for Development

Run `make watch` in the `Conch` parent directory to start the API service,
webpack in development mode (automatically watches and builds source files),
and browser-sync (automatically reloads your browser on source changes).


## Build for Production

Run `make web-assets` in the `Conch` parent directory to build UI source files
optimized for production.
