var m = require("mithril");
var t = require("i18n4v");
import Tooltip from "tooltip.js";

function addToolTip(title, placement = "right") {
    return ({ dom }) => {
        new Tooltip(dom, { title: title, placement: placement });
    };
}

module.exports = {
    deviceValidated: {
        view: () => {
            return m(
                "i.material-icons",
                {
                    oncreate: addToolTip(
                        t("Device has completed validation. Good to ship.")
                    ),
                },
                "check_circle"
            );
        },
    },

    passValidation: {
        view: () => {
            return m(
                "i.material-icons",
                {
                    oncreate: addToolTip(t("Device passes validation")),
                },
                "check"
            );
        },
    },

    failValidation: {
        view: () => {
            return m(
                "i.material-icons",
                {
                    oncreate: addToolTip(t("Device fails validation")),
                },
                "error_outline"
            );
        },
    },

    deviceReporting: {
        view: () => {
            return m(
                "i.material-icons",
                {
                    oncreate: addToolTip(t("Device reporting to Conch")),
                },
                "cloud_upload"
            );
        },
    },

    noReport: {
        view: () => {
            return m(
                "i.material-icons",
                {
                    oncreate: addToolTip(t("No reports collected from device")),
                },
                "help_outline"
            );
        },
    },

    firmwareUpdating: m("i.material-icons", "refresh"),

    findDeviceInRack: m("i.material-icons.md-18", "dns"),

    showRack: m("i.material-icons.md-18", "dns"),

    deviceProblems: m("i.material-icons.md-18", "report_problem"),

    deviceReport: m("i.material-icons.md-18", "description"),

    showRelay: m("i.material-icons.md-18", "router"),

    relayActive: m("i.material-icons", "router"),

    warning: m("i.material-icons", "warning"),

    nav: {
        status: m("i.material-icons", "assessment"),
        racks: m("i.material-icons", "dns"),
        problems: m("i.material-icons", "report_problem"),
        devices: m("i.material-icons", "description"),
        relays: m("i.material-icons", "router"),
        logout: m("i.material-icons", "exit_to_app"),
        feedback: m("i.material-icons", "message"),
        language: m("i.material-icons", "language"),
    },

    ui: {
        close: m("i.material-icons", "close"),
    },
};
