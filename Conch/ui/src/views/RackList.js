var m = require("mithril");
var Rack = require("../models/Rack");

module.exports = {
    oninit: Rack.loadRooms,
    view: function() {
        return m(".room-list", Object.keys(Rack.rackRooms).map(

          function(roomName) {

            return [
              m("h3.room-list-header", roomName),
              m(".rack-list", Rack.rackRooms[roomName].map(
                function(rack) {
                  return m("a.rack-list-item",
                    {href: "/rack/" + rack.id, oncreate: m.route.link},
                    "Name: " + rack.name + ", Role: "
                      + rack.role + ", Size: " + rack.size
                  );
              }))

            ];
          })
        );
    }
};
