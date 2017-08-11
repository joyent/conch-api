var m = require("mithril");
var t = require("i18n4v");
var Rack = require("../models/Rack");
var Problem = require("../models/Problem");

var allRacks = {
    oninit: Rack.loadRooms,
    view: function(vnode) {
        return Object.keys(Rack.rackRooms).map(
            function(roomName) {
                return [
                    m("h3.selection-list-header", roomName),
                    m(".selection-list-group", Rack.rackRooms[roomName].map(
                        function(rack) {
                            return m("a.selection-list-item",
                                {
                                    href: "/rack/" + rack.id,
                                    oncreate: m.route.link,
                                    onclick: function() {
                                        Rack.load(rack.id);
                                    },
                                    class: rack.id === Rack.current.id ?
                                    "selection-list-item-active" : ""
                                },
                                m(".pure-g", [
                                    m(".pure-u-1-3", m("b", t("Name"))),
                                    m(".pure-u-1-3", m("b", t("Role"))),
                                    m(".pure-u-1-3", m("b", t("RU"))),

                                    m(".pure-u-1-3", rack.name),
                                    m(".pure-u-1-3", rack.role),
                                    m(".pure-u-1-3", rack.size)
                                ])
                            );
                        }))
                ];
        });
    }
};

var makeSelection = {
    view: function() {
        return m(".make-selection", t("Select Rack"));
    }
};

var rackLayout = {
    oninit: function(vnode) {
        Rack.load(vnode.attrs.id);
        Rack.highlightDevice = vnode.attrs.device;
        Problem.loadDeviceProblems();
    },
    view: function() {
        return [
            Rack.assignSuccess ?
                m(".notification.notification-success",
                    t("Assign Success"))
                : null,
            m("form.pure-form.pure-g",
                { onsubmit: function (e){
                    Rack.assignDevices(Rack.current);
                } },
                m(".rack-layout-table.pure-u-1", m(rackLayoutTable)),
                m(".rack-layout-footer",
                    m("button.pure-button.pure-button-primary[type=submit]", t("Assign Devices"))
                )
            )
        ];
    }
};

// Focus on the next Slot input when Enter is pressed.
function enterAsTab(e) {
    try {
        var nextInput = e.target.parentNode.parentNode
                .nextSibling.lastChild.lastChild;
        if (e.which == 13 && nextInput) {
                nextInput.focus();
                e.preventDefault();
            }
    }
    catch(e){ }
}

var rackLayoutTable = { view: function () {
    return m("table.pure-table.pure-table-horizontal.pure-table-striped", [
        m("thead", m("tr", [
            m("th", t("Slot Number")),
            m("th", t("Name")),
            m("th", t("Vendor")),
            m("th", t("RU Height")),
            m("th", t("Device")),
            m("th", t("Status")),
        ])),
        m("tbody",
            Object.keys(Rack.current.slots || {}).reverse().map(function(slotId) {
                var slot = Rack.current.slots[slotId];
                var healthy = slot.occupant && ! Problem.devices[slot.occupant];
                return m("tr",
                    [
                        m("td", slotId),
                        m("td", slot.name),
                        m("td", slot.vendor),
                        m("td", slot.size),
                        m("td",
                            m("input[type=text]",
                                {
                                    oninput: m.withAttr("value", function(value) {
                                            slot.assignment = value;
                                        }),
                                    id: "slot-" + slot,
                                    placeholder: slot.occupant ? "" : t("Unassigned"),
                                    onkeypress: enterAsTab,
                                    value: slot.assignment || slot.occupant || "",
                                    class:
                                        Rack.highlightDevice === slot.occupant ?
                                        "row-highlight" : ""
                                }
                            )
                        ),
                        m("td", slot.occupant ?
                            m("a.pure-button", {
                                href: "/device/" + slot.occupant,
                                oncreate: m.route.link,
                                title: t("Show Device Report"),
                                class: healthy ? "" : "color-failure"
                            },
                                healthy ? t("Pass") : t("FAIL") )
                            : ""
                        )
                    ]);
            }))
    ]);
} };

module.exports = {
    allRacks      : allRacks,
    makeSelection : makeSelection,
    rackLayout    : rackLayout,
};
