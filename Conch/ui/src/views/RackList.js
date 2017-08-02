var m = require("mithril");
var Rack = require("../models/Rack");

module.exports = {
    oninit: Rack.loadList,
    view: function() {
        return m(".rack-list", Rack.list.map(function(rack) {
            return m("a.rack-list-item", {href: "/edit/" + rack.id, oncreate: m.route.link}, user);
        }));
    }
};
