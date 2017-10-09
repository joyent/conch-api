import m from "mithril";
import t from "i18n4v";
import Device from "../models/Device";
import Rack from "../models/Rack";
import Relay from "../models/Relay";
import Feedback from "../models/Feedback";
import DeviceStatus from "./component/DeviceStatus";
import Icons from "./component/Icons";
import Table from "./component/Table";

const allRacks = {
    loading: true,
    oninit: ({ state }) => {
        Promise.all([Rack.loadRooms(), Relay.loadActiveRelays()]).then(
            () => (state.loading = false)
        );
    },
    view: ({ state }) => {
        if (state.loading) return m(".loading", "Loading...");
        return Object.keys(Rack.rackRooms).map(roomName => [
            m("h3.selection-list-header", roomName),
            m(
                ".selection-list-group",
                Rack.rackRooms[roomName].map(({id, name, role, size}) => m(
                    "a.selection-list-item",
                    {
                        href: `/rack/${id}`,
                        oncreate: m.route.link,
                        onclick() {
                            Rack.load(id);
                        },
                        class:
                            id === Rack.current.id
                                ? "selection-list-item-active"
                                : "",
                    },
                    m(".pure-g", [
                        m(".pure-u-1-3", m("b", t("Name"))),
                        m(".pure-u-1-3", m("b", t("Role"))),
                        m(".pure-u-1-3", m("b", t("RU"))),

                        m(".pure-u-1-3", name),
                        m(".pure-u-1-3", role),
                        m(".pure-u-1-3", size),
                    ])
                ))
            ),
        ]);
    },
};

const makeSelection = {
    view() {
        return m(".make-selection", t("Select Rack"));
    },
};

const rackLayout = {
    oninit({attrs}) {
        Rack.load(attrs.id);
        Rack.highlightDevice = attrs.device;
    },
    view() {
        const activeRelay = Relay.activeList.find(({location}) => {
            return location && location.rack_id === Rack.current.id;
        });
        const relayActive = activeRelay
            ? m(
                  ".pure-u-1",
                  m(
                      ".rack-relay-active",
                      m(
                          "a.pure-button",
                          {
                              href: `/relay/${activeRelay.id}`,
                              oncreate: m.route.link,
                          },
                          Icons.relayActive,
                          t("Relay Active in Rack")
                      )
                  )
              )
            : null;
        return [
            Rack.assignSuccess
                ? m(".notification.notification-success", t("Assign Success"))
                : null,
            m(
                "form.pure-form.pure-g",
                {
                    onsubmit(e) {
                        Rack.assignDevices(Rack.current);
                    },
                },
                m(
                    ".pure-u-1",
                    Table(
                        t("Rack Details"),
                        [t("Datacenter"), t("Rack Name"), t("Rack Role")],
                        [
                            [
                                Rack.current.datacenter,
                                Rack.current.name,
                                Rack.current.role,
                            ],
                        ]
                    )
                ),
                relayActive,
                m(".pure-u-1", m(rackLayoutTable)),
                m(
                    ".rack-layout-footer",
                    m(
                        "button.pure-button.pure-button-primary[type=submit]",
                        t("Assign Devices")
                    )
                )
            ),
        ];
    },
};

// Focus on the next Slot input when Enter is pressed.
function enterAsTab(e) {
    try {
        const nextInput =
            e.target.parentNode.parentNode.nextSibling.lastChild.lastChild;
        if (e.which == 13 && nextInput) {
            nextInput.focus();
            e.preventDefault();
        }
    } catch (e) {}
}

var rackLayoutTable = {
    view() {
        function reportButton({occupant}) {
            const healthButton = {
                PASS: m(
                    "a.pure-button",
                    {
                        href: `/device/${occupant.id}`,
                        oncreate: m.route.link,
                        title: t("Show Device Report"),
                    },
                    t("Pass")
                ),
                UNKNOWN: t("No Report"),
                FAIL: m(
                    "a.pure-button",
                    {
                        href: `/problem/${occupant.id}`,
                        oncreate: m.route.link,
                        title: t("Show Device Report"),
                        class: "color-failure",
                    },
                    t("FAIL")
                ),
            };
            return healthButton[occupant.health];
        }
        function deviceInput(slot) {
            return m("input[type=text]", {
                oninput: m.withAttr("value", value => {
                    slot.assignment = value;
                }),
                placeholder: slot.occupant ? "" : t("Unassigned"),
                onkeypress: enterAsTab,
                value: slot.assignment || (slot.occupant || {}).id || "",
                class:
                    Rack.highlightDevice &&
                    Rack.highlightDevice === (slot.occupant || {}).id
                        ? "row-highlight"
                        : "",
            });
        }
        function flagDevice({occupant}, slotId) {
            return m(
                "a.pure-button",
                {
                    onclick() {
                        Feedback.sendFeedback(
                            "[NOTICE] User Flagged Device",
                            `Device ${occupant.id} in slot ${slotId} was flagged by the user.`,
                            () => {
                                alert(
                                    t("Administrators notified about device")
                                );
                            }
                        );
                    },
                    title: t("Notify administrators about device"),
                },
                m("i.material-icons.md-18", "flag")
            );
        }
        // TODO: Replace this with DeviceStatus after figuring out why it causes icons to duplicate
        const statusIndicators = {
            view({attrs}) {
                const occupant = attrs.occupant;
                if (occupant) {
                    let healthIcon;
                    if (occupant.validated && occupant.health === "PASS")
                        healthIcon = Icons.deviceValidated;
                    else if (occupant.health === "PASS")
                        healthIcon = Icons.passValidation;
                    else if (occupant.health === "FAIL")
                        healthIcon = Icons.failValidation;
                    else healthIcon = Icons.noReport;

                    return m(".rack-status", [
                        m(healthIcon),
                        Device.isActive(occupant)
                            ? m(Icons.deviceReporting)
                            : null,
                    ]);
                }
                return m(".rack-status");
            },
        };

        return Table(
            t("Rack Layout"),
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
            Object.keys(Rack.current.slots || {})
                .reverse()
                .map(slotId => {
                    const slot = Rack.current.slots[slotId];
                    return [
                        m(statusIndicators, { occupant: slot.occupant }),
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
    },
};

export default {
    allRacks,
    makeSelection,
    rackLayout,
};
