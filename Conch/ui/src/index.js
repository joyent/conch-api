var m = require("mithril");

var Rack = require("./views/Rack");
var Layout = require("./views/Layout");
var Login = require("./views/Login");

m.route(document.body, "/login", {
    "/racks": {
        render: function() {
            return m(Layout, m(Rack.allRacks));
        }
    },
    "/rack/:id": {
        render: function(vnode) {
            return m(Layout, m(Rack.rackLayout, vnode.attrs));
        }
    },
    "/login": Login
});
