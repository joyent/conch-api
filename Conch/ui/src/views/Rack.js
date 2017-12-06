import m from "mithril";
import t from "i18n4v";
import Auth from "../models/Auth";
import Device from "../models/Device";
import Rack from "../models/Rack";
import Relay from "../models/Relay";
import Feedback from "../models/Feedback";
import Workspace from "../models/Workspace";
import DeviceStatus from "./component/DeviceStatus";
import Icons from "./component/Icons";
import Table from "./component/Table";

const allRacks = {
    loading: true,
    oninit: ({ state }) => {
        Auth.requireLogin(
            Workspace.withWorkspace(workspaceId => {
                Promise.all([
                    Relay.loadActiveRelays(workspaceId),
                    Rack.loadRooms(workspaceId),
                ]).then(() => (state.loading = false));
            })
        );
    },
    view: ({ state }) => {
        if (state.loading) return m(".loading", "Loading...");
        return Object.keys(Rack.rackRooms).map(roomName => [
            m("h3.selection-list-header", roomName),
            m(
                ".selection-list-group",
                Rack.rackRooms[roomName].map(({ id, name, role, size }) =>
                    m(
                        "a.selection-list-item",
                        {
                            href: `/rack/${id}`,
                            oncreate: m.route.link,
                            onclick() {
                                Workspace.withWorkspace(workspaceId =>
                                    Rack.load(workspaceId, id)
                                );
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
                    )
                )
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
    oninit({ attrs }) {
        Auth.requireLogin(
            Workspace.withWorkspace(workspaceId => {
                Rack.load(workspaceId, attrs.id);
                Rack.highlightDevice = attrs.device;
            })
        );
    },
    view() {
        const activeRelay = Relay.activeList.find(({ location }) => {
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
                        Workspace.withWorkspace(workspaceId =>
                            Rack.assignDevices(workspaceId, Rack.current)
                        );
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

var rackLayoutTable = {
    view({ state }) {
        function reportButton({ occupant }) {
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
                value: slot.assignment || (slot.occupant || {}).id || "",
                class:
                    Rack.highlightDevice &&
                    Rack.highlightDevice === (slot.occupant || {}).id
                        ? "row-highlight"
                        : "",
            });
        }
        function deviceAssetTag(slot) {
            if (!slot.occupant) {
                return m("input[type=text]", {
                    placeholder: t("Must first assign device"),
                    disabled: true,
                });
            }
            const deviceId = slot.occupant.id;
            if (!state[deviceId]) {
                state[deviceId] = {};
                state[deviceId].assetTag = slot.occupant.asset_tag || null;
            }
            return m("input[type=text]", {
                oninput: m.withAttr("value", value => {
                    state[deviceId].assetTag = value;
                }),
                onchange: () => {
                    Device.setAssetTag(deviceId, state[deviceId].assetTag);
                },
                placeholder: t("Device asset tag"),
                value: state[deviceId].assetTag || "",
            });
        }
        function flagDevice({ occupant }, slotId) {
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
            view({ attrs }) {
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
                t("Asset Tag"),
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
                        deviceAssetTag(slot),
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
