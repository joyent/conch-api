var m = require("mithril");

var Rack = require("./views/Rack");
var Layout = require("./views/Layout");
var Login = require("./views/Login");

m.route(document.body, "/login", {
    "/rack": {
        render: function() {
            return m(Layout,
              m(Rack.allRacks,
                m(".select-rack.pure-u-2-3", "Select a rack in the sidebar")
              ));
        }
    },
    "/rack/:id": {
        render: function(vnode) {
            return m(Layout,
              m(Rack.allRacks,
                m(Rack.rackLayout, vnode.attrs))
            );
        }
    },
    "/login": Login
});
