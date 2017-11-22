import m from "mithril";
import moment from "moment";

const Device = {
    deviceIds: [],
    current: null,
    loadDeviceIds(workspaceId) {
        return m
            .request({
                method: "GET",
                url: `/workspace/${workspaceId}/device`,
                data: { ids_only: 1 },
                withCredentials: true,
            })
            .then(res => {
                Device.deviceIds = res.sort();
            })
            .catch(e => {
                if (e.error === "unauthorized") {
                    m.route.set("/login");
                } else {
                    console.log(`Error in GET /device: ${e.message}`);
                }
            });
    },

    loadDevices(workspaceId) {
        return m
            .request({
                method: "GET",
                url: `/workspace/${workspaceId}/device`,
                withCredentials: true,
            })
            .then(res => {
                Device.devices = res.sort((a, b) => {
                    if (a.id < b.id) {
                        return -1;
                    }
                    if (a.id > b.id) {
                        return 1;
                    }
                    return 0;
                });
            })
            .catch(e => {
                if (e.error === "unauthorized") {
                    m.route.set("/login");
                } else {
                    console.log(`Error in GET /device: ${e.message}`);
                }
            });
    },

    loadDevice(deviceId) {
        return m
            .request({
                method: "GET",
                url: `/device/${deviceId}`,
                withCredentials: true,
            })
            .then(res => {
                Device.current = res;
            })
            .catch(e => {
                if (e.error === "unauthorized") {
                    m.route.set("/login");
                } else {
                    console.log(`Error in GET /device: ${e.message}`);
                }
            });
    },

    updatingFirmware: false,
    loadFirmwareStatus(deviceId) {
        return m
            .request({
                method: "GET",
                url: `/device/${deviceId}/settings/firmware`,
                withCredentials: true,
                extract(xhr) {
                    return {
                        status: xhr.status,
                        body: JSON.parse(xhr.response),
                    };
                },
            })
            .then(res => {
                Device.updatingFirmware = res.body.firmware === "updating";
            })
            .catch(e => {
                if (e.status === 404) {
                    Device.updatingFirmware = false;
                } else if (e.status === 401) {
                    m.route.set("/login");
                } else {
                    console.log(`Error in GET /device: ${e.message}`);
                }
            });
    },

    rackLocation: null,
    getDeviceLocation: deviceId => {
        return m
            .request({
                method: "GET",
                url: `/device/${deviceId}/location`,
                withCredentials: true,
                extract(xhr) {
                    return {
                        status: xhr.status,
                        body: JSON.parse(xhr.response),
                    };
                },
            })
            .then(res => res.body)
            .catch(e => {
                if (e.status === 401) {
                    m.route.set("/login");
                } else if (e.status === 409 || e.status === 400) {
                    Device.rackLocation = null;
                } else {
                    console.log(
                        `Error in GET /device/${deviceId}/location: ${e.message}`
                    );
                }
            });
    },
    loadRackLocation(deviceId) {
        return Device.getDeviceLocation(deviceId).then(
            res => (Device.rackLocation = res)
        );
    },

    logs: [],
    loadDeviceLogs(deviceId, limit) {
        return m
            .request({
                method: "GET",
                url: `/device/${deviceId}/log`,
                data: { limit },
                withCredentials: true,
            })
            .then(res => {
                Device.logs = res;
            })
            .catch(e => {
                console.log(
                    `Error in GET /device/${deviceId}/log: ${e.message}`
                );
            });
    },

    // A device is active if it was last seen in the last 5 minutes
    isActive(device) {
        if (device.last_seen) {
            const lastSeen = moment(device.last_seen);
            const fiveMinutesAgo = moment().subtract(5, "m");
            return fiveMinutesAgo < lastSeen;
        }
        return false;
    },
};

export default Device;
