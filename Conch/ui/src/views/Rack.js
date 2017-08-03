var m = require("mithril");
var Rack = require("../models/Rack");

var allRacks = {
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


var rackLayout = {
    oninit: function(vnode) { Rack.load(vnode.attrs.id) },
    view: function() {
        console.log(Rack.current.slots);
        return [
            m("h1", Rack.current.datacenter),
            m("h2", Rack.current.name),
            m("h2", Rack.current.role),
            m("table.pure-table.pure-table-horizontal.pure-table-striped", [
                m("thead", m("tr", [
                    m("th", "Slot number"),
                    m("th", "Name"),
                    m("th", "Alias"),
                    m("th", "Vendor"),
                    m("th", "Size")
                ])),
                m("tbody",
                    Object.keys(Rack.current.slots || {}).map(function(slot) {
                        return m("tr", [
                            m("td", slot),
                            m("td", Rack.current.slots[slot].name),
                            m("td", Rack.current.slots[slot].alias),
                            m("td", Rack.current.slots[slot].vendor),
                            m("td", Rack.current.slots[slot].size),
                        ]);
                    }))
            ])
        ];
    }
};

module.exports = { allRacks: allRacks, rackLayout: rackLayout };
