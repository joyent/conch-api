var m = require("mithril");
var Rack = require("../models/Rack");

module.exports = {
    oninit: Rack.loadRacks,
    view: function() {
        // TODO add code here
        console.log("do something");
        return m(".rack-list", Rack.list.map(function(rack) {
            return m(".rack-list-item", rack.name);
        }));
    }
}
