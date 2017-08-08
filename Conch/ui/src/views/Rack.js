var m = require("mithril");
var t = require("i18n4v");
var Rack = require("../models/Rack");

var allRacks = {
    oninit: Rack.loadRooms,
    view: function(vnode) {
        return [
            m(".selection-list.pure-u-1-6", Object.keys(Rack.rackRooms).map(
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
                                        m(".pure-u-1", t("Name") + ": " + rack.name),
                                        m(".pure-u-1", t("Role") + ": " + rack.role),
                                        m(".pure-u-1", t("Size") + ": " + rack.size)
                                    ])
                                );
                            }))

                    ];
                })
        ),
        vnode.children.length > 0 ?
            vnode.children
            : m(".make-selection.pure-u-3-4", t('Select Rack'))
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
            m("th", t("Alias")),
            m("th", t("Vendor")),
            m("th", t("Size")),
            m("th", t("Device"))
        ])),
        m("tbody",
            Object.keys(Rack.current.slots || {}).reverse().map(function(slot) {
                return m("tr",
                    [
                        m("td", slot),
                        m("td", Rack.current.slots[slot].name),
                        m("td", Rack.current.slots[slot].alias),
                        m("td", Rack.current.slots[slot].vendor),
                        m("td", Rack.current.slots[slot].size),
                        m("td",
                            m("input[type=text]",
                                {
                                    oninput:
                                    m.withAttr("value",
                                        function(value) {
                                            Rack.current.slots[slot].occupant = value;
                                        }
                                    ),
                                    id: "slot-" + slot,
                                    placeholder: t("Unassigned"),
                                    onkeypress: enterAsTab,
                                    value: Rack.current.slots[slot].occupant,
                                    class:
                                        Rack.highlightDevice === Rack.current.slots[slot].occupant ?
                                            "row-highlight" : ""
                                }
                            )
                        )
                    ]);
            }))
    ]);
} };

var rackLayout = {
    oninit: function(vnode) {
        Rack.load(vnode.attrs.id);
        Rack.highlightDevice = vnode.attrs.device;
    },
    view: function() {
        return m(".content-pane.pure-u-3-4", [
            Rack.assignSuccess ?
                m(".notification.notification-success",
                    t("Assign Success"))
                : null,
            m(".pure-g", [
                m(".pure-u-1-3", m("h3", t("Datacenter"))),
                m(".pure-u-1-3", m("h3", t("Rack Name"))),
                m(".pure-u-1-3", m("h3", t("Rack Role"))),
                m(".pure-u-1-3", Rack.current.datacenter),
                m(".pure-u-1-3", Rack.current.name),
                m(".pure-u-1-3", Rack.current.role),
                m(".pure-u-1",
                    m("form.pure-form",
                        { onsubmit: function (e){
                            Rack.assignDevices(Rack.current);
                        } },
                        [
                            m(rackLayoutTable),
                            m("button.pure-button.pure-button-primary[type=submit]", t("Assign Devices")),
                        ])
                )
            ])
        ]);
    }
};

module.exports = { allRacks: allRacks, rackLayout: rackLayout };
