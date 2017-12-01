import m from "mithril";
import t from "i18n4v";
import Auth from "../models/Auth";
import Device from "../models/Device";
import Workspace from "../models/Workspace";
import Table from "./component/Table";
import Icons from "./component/Icons";

const allDevices = {
    oninit({attrs}) {
        Auth.requireLogin(
            Workspace.withWorkspace(workspaceId => {
                Device.loadDeviceIds(workspaceId);
            })
        );
    },
    view(vnode) {
        return Device.deviceIds.map(deviceId => m(
            "a.selection-list-item",
            {
                href: `/device/${deviceId}`,
                onclick() {
                    loadDeviceDetails(deviceId);
                },
                oncreate: m.route.link,
                class:
                    Device.current && deviceId === Device.current.id
                        ? "selection-list-item-active"
                        : "",
            },
            deviceId
        ));
    },
};

const makeSelection = {
    view() {
        return m(".make-selection", t("Select Device"));
    },
};

function loadDeviceDetails(id) {
    return Auth.requireLogin(
        Promise.all([
            Device.loadDevice(id),
            Device.loadRackLocation(id),
            Device.loadFirmwareStatus(id),
            Device.loadDeviceLogs(id, 20),
        ])
    );
}

const deviceReport = {
    oninit({attrs}) {
        loadDeviceDetails(attrs.id);
    },
    view(vnode) {
        if (!Device.current) {
            return m(".make-selection", t("No report for device"));
        }

        const title = m(
            ".pure-u-1.text-center",
            m("h1", `${t("Device")}: ${Device.current.id}`)
        );

        const basicInfo = m(
            ".pure-u-1",
            Table(
                t("Basic Device Info"),
                [
                    t("Product Name"),
                    t("BIOS Version"),
                    t("System UUID"),
                    t("State"),
                ],
                [
                    [
                        Device.current.latest_report.product_name ||
                            t("UNKNOWN"),
                        Device.current.latest_report.bios_version ||
                            t("UNKNOWN"),
                        Device.current.latest_report.system_uuid ||
                            t("UNKNOWN"),
                        Device.current.state,
                    ],
                ]
            )
        );

        const statusRows = [];
        let healthStatus;
        if (Device.current.validated && Device.current.health === "PASS")
            healthStatus = [
                m(Icons.deviceValidated),
                t("Device has completed validation. Good to ship."),
            ];
        else if (Device.current.health === "PASS")
            healthStatus = [
                m(Icons.passValidation),
                t("Device passes validation tests"),
            ];
        else if (Device.current.health === "FAIL")
            healthStatus = [
                m(Icons.failValidation),
                t("Device fails validation tests"),
            ];
        else
            healthStatus = [
                m(Icons.noReport),
                t("No reports collected from device"),
            ];
        statusRows.push(healthStatus);

        if (Device.updatingFirmware)
            statusRows.push([
                Icons.firmwareUpdating,
                t("Firmware Currently Updating"),
            ]);

        if (Device.isActive(Device.current))
            statusRows.push([
                m(Icons.deviceReporting),
                t(
                    "Actively reporting to Conch (Reported in the last 5 minutes)"
                ),
            ]);

        const firmwareUpdatingNotification = Device.updatingFirmware
            ? m(
                  ".pure-u-1",
                  m(
                      ".notification.notification-success",
                      t("Firmware Currently Updating")
                  )
              )
            : null;

        const deviceStatus = m(
            ".pure-u-1",
            Table(
                t("Device Status"),
                [t("Status"), t("Description")],
                statusRows
            )
        );

        const deviceLocation = m(
            ".pure-u-1",
            Device.rackLocation
                ? Table(
                      t("Device Location"),
                      [t("Datacenter"), t("Rack"), t("Role"), t("Unit")],
                      [
                          [
                              Device.rackLocation.datacenter.name,
                              Device.rackLocation.rack.name,
                              Device.rackLocation.rack.role,
                              Device.rackLocation.rack.unit,
                          ],
                      ]
                  )
                : m(
                      "h3.text-center",
                      t("Device has not been assigned a location")
                  )
        );

        const environment = Device.current.latest_report.temp
            ? Table(
                  t("Environment"),
                  [t("Name"), t("Temperature")],
                  Object.keys(Device.current.latest_report.temp)
                      .sort()
                      .map(k => [k, Device.current.latest_report.temp[k]])
              )
            : null;
        const network = Device.current.latest_report.interfaces
            ? Table(
                  t("Network"),
                  [
                      t("Name"),
                      t("MAC"),
                      t("IP Address"),
                      t("State"),
                      t("Product"),
                      t("Peer Switch"),
                      t("Peer Port"),
                      t("Peer MAC"),
                  ],
                  Object.keys(Device.current.latest_report.interfaces)
                      .sort()
                      .map(k => {
                          const iface =
                              Device.current.latest_report.interfaces[k];
                          return [
                              k,
                              iface.mac,
                              iface.ipaddr,
                              iface.state,
                              iface.product,
                              iface.peer_switch,
                              iface.peer_port,
                              iface.peer_mac,
                          ];
                      })
              )
            : null;
        const disks = Device.current.latest_report.disks
            ? Table(
                  t("Storage"),
                  [
                      t("Serial Number"),
                      t("HBA"),
                      t("Slot Number"),
                      t("Vendor"),
                      t("Model"),
                      t("Size"),
                      t("Drive Type"),
                      t("Transport"),
                      t("Firmware"),
                      t("Health"),
                      t("Temperature"),
                  ],
                  Object.keys(Device.current.latest_report.disks)
                      .sort()
                      .map(k => {
                          const disk = Device.current.latest_report.disks[k];
                          return [
                              k,
                              disk.hba,
                              disk.slot,
                              disk.vendor,
                              disk.model,
                              disk.size,
                              disk.drive_type,
                              disk.transport,
                              disk.firmware,
                              disk.health,
                              disk.temp,
                          ];
                      })
              )
            : null;
        const validations = Table(
            t("Device Validation Tests"),
            [t("Status"), t("Type"), t("Name"), t("Metric"), t("Log")],
            Device.current.validations
                .sort((a, b) => {
                    if (a.component_type < b.component_type)
                        return -1;
                    if (a.component_type > b.component_type)
                        return 1;
                    if (a.component_name < b.component_name)
                        return -1;
                    if (a.component_name > b.component_name)
                        return 1;
                    return 0;
                })
                .map(v => [
                v.status ? m('i') : Icons.warning,
                v.component_type,
                v.component_name,
                v.metric,
                v.log,
            ])
        );
        const logs = Table(
            t("Devices Logs (20 most recent)"),
            [t("Component Type"), t("Component ID"), t("Time"), t("Log")],
            Device.logs.map(({component_type, component_id, created, msg}) => [
                component_type,
                component_id,
                created,
                // pre requried to preserve multi-lines
                m("span.log-text", msg),
            ])
        );
        return m(".pure-g", [
            firmwareUpdatingNotification,
            basicInfo,
            deviceStatus,
            deviceLocation,
            m(".pure-u-1", m("hr")),
            m(".pure-u-1", m("h2.text-center", t("Latest Device Report"))),
            environment,
            network,
            disks,
            validations,
            logs,
        ]);
    },
};

export default {
    allDevices,
    makeSelection,
    deviceReport,
};
