var m = require("mithril");
var t = require("i18n4v");

var Device   = require("../models/Device");
var Rack     = require("../models/Rack");
var Relay    = require("../models/Relay");
var Feedback = require("../models/Feedback");

var DeviceStatus = require("./component/DeviceStatus");
var Icons        = require("./component/Icons");
var Table        = require("./component/Table");

var allRacks = {
    loading : true,
    oninit : ({state}) => {
        Promise.all([
            Rack.loadRooms(),
            Relay.loadActiveRelays()
        ]
        ).then(() => state.loading = false);
    },
    view : ({state}) => {
        if (state.loading)
            return m(".loading", "Loading...");
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
    },
    view: function() {
        const activeRelay  =
            Relay.activeList.find( relay => relay.location.rack_id === Rack.current.id);
        const relayActive =
            activeRelay ?
                m(".pure-u-1", m(".rack-relay-active",
                    m("a.pure-button", {href : `/relay/${relay.id}`, oncreate: m.route.link },
                        Icons.relayActive, t("Relay Active in Rack"))
                    ))
              : null;
        return [
            Rack.assignSuccess ?
                m(".notification.notification-success",
                    t("Assign Success"))
                : null,
            m("form.pure-form.pure-g",
                { onsubmit: function (e){
                    Rack.assignDevices(Rack.current);
                } },
                m(".pure-u-1", Table( t("Rack Details"),
                    [
                        t("Datacenter"), t("Rack Name"), t("Rack Role")
                    ],[[
                        Rack.current.datacenter, Rack.current.name, Rack.current.role
                    ]])
                ),
                relayActive,
                m(".pure-u-1", m(rackLayoutTable)),
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

var rackLayoutTable = {
    view: function() {
        function reportButton(slot) {
            var healthy =
                slot.occupant && slot.occupant.health === 'PASS';
            return m("a.pure-button", {
                href: healthy ? "/device/" + slot.occupant.id : "/problem/" + slot.occupant.id,
                oncreate: m.route.link,
                title: t("Show Device Report"),
                class: healthy ? "" : "color-failure"

            }, healthy ? t("Pass") : t("FAIL") );
        }
        function deviceInput(slot){
            return m("input[type=text]",
                {
                    oninput: m.withAttr("value", function(value) {
                        slot.assignment = value;
                    }),
                    placeholder: slot.occupant ? "" : t("Unassigned"),
                    onkeypress: enterAsTab,
                    value: slot.assignment || (slot.occupant || {}).id || "",
                    class:
                        Rack.highlightDevice
                        && Rack.highlightDevice === (slot.occupant || {}).id
                        ?  "row-highlight" : ""
                }
            );
        }
        function flagDevice(slot, slotId) {
            return m("a.pure-button", {
                onclick: function (){
                    Feedback.sendFeedback(
                        "[NOTICE] User Flagged Device",
                        "Device " + slot.occupant.id + " in slot " + slotId + " was flagged by the user.",
                        function(){
                            alert(t("Administrators notified about device"));
                        }
                    );
                },
                title: t("Notify administrators about device")
            }, m("i.material-icons.md-18", "flag"));
        }
        // TODO: Replace this with DeviceStatus after figuring out why it causes icons to duplicate
        var statusIndicators = {
            view : function(vnode) {
                var occupant = vnode.attrs.occupant;
                if (occupant) {
                    var healthIcon;
                    if (occupant.health === 'PASS')
                        healthIcon = Icons.passValidation;
                    else if (occupant.health === 'FAIL')
                        healthIcon = Icons.failValidation;
                    else
                        healthIcon = Icons.noReport;
                    return m(".rack-status",
                        [
                            healthIcon,
                            Device.isActive(occupant) ?
                            Icons.deviceReporting
                            : null,
                        ]);
                }
                return m(".rack-status");
            }
        };


        return Table(t("Rack Layout"),
            [
                t("Status"),
                t("Slot Number"),
                t("Name"),
                t("Vendor"),
                t("RU Height"),
                t("Device"),
                t("Report"),
                t("Actions"),
            ],
            Object.keys(Rack.current.slots || {}).reverse().map(function(slotId) {
                var slot = Rack.current.slots[slotId];
                return [
                    m(statusIndicators, {occupant : slot.occupant }),
                    slotId,
                    slot.name,
                    slot.vendor,
                    slot.size,
                    deviceInput(slot),
                    slot.occupant ? reportButton(slot) : null,
                    slot.occupant ? flagDevice(slot, slotId) : null,
                ];
            })
        );
    }
};

module.exports = {
    allRacks      : allRacks,
    makeSelection : makeSelection,
    rackLayout    : rackLayout,
};
