import m from "mithril";
import t from "i18n4v";

import Auth from "../models/Auth";
import Problem from "../models/Problem";
import Rack from "../models/Rack";
import Table from "./component/Table";
import Validation from "../models/Validation";
import ValidationState from "../models/ValidationState";
import Workspace from "../models/Workspace";

function categoryTitle(category) {
    switch (category) {
        case "failing":
            return t("Validation Failed");
        case "unlocated":
            return t("No Location Assigned");
        case "unreported":
            return t("No Device Report Collected");
        default:
            return t("Other Problems");
    }
}

const selectProblemDevice = {
    loading: true,
    oninit: ({ state }) => {
        Auth.requireLogin(
            Workspace.withWorkspace(workspaceId =>
                Problem.loadDeviceProblems(workspaceId).then(
                    () => (state.loading = false)
                )
            )
        );
    },
    view: ({ state, attrs }) => {
        if (state.loading) return m(".loading", "Loading...");

        return Object.keys(Problem.devices).map(category => {
            const devices = Problem.devices[category];
            return [
                m("h4.selection-list-header", categoryTitle(category)),
                m(
                    ".selection-list-group",
                    Object.keys(devices).map(deviceId => {
                        // Assign the current device if it matches the URL parameter
                        if (attrs.id && attrs.id === deviceId)
                            Problem.current = devices[deviceId];

                        return m(
                            "a.selection-list-item",
                            {
                                href: `/problem/${deviceId}`,
                                onclick() {
                                    Problem.current = devices[deviceId];
                                },
                                oncreate: m.route.link,
                            },
                            m(".pure-g", [
                                m(".pure-u-1", `${t("Device")} ${deviceId}`),
                            ])
                        );
                    })
                ),
            ];
        });
    },
};

const makeSelection = {
    view() {
        return m(".make-selection", t("Select Device"));
    },
};

const showDevice = {
    loading: true,
    oninit({ attrs, state }) {
        if (attrs.id) {
            Auth.requireLogin(
                Promise.all([
                    Validation.load(),
                    ValidationState.loadForDevice(attrs.id).then(
                        () => (state.loading = false)
                    ),
                ])
            );
        }
    },
    view({ attrs, state }) {
        if (!Problem.current) return m(".make-selection", t("Select Device"));
        if (state.loading) return m(".loading", "Loading...");

        const problemRows = Problem.current.problems.map(
            ({ component_type, component_name, criteria, log }) => [
                component_type,
                component_name,
                criteria.condition,
                log,
            ]
        );
        // Format the validation state results like the problems.
        const validationRows = ValidationState.currentList.reduce((acc, vs) => {
            vs.results.forEach(
                ({ category, validation_id, status, message }) => {
                    if (status !== "pass")
                        acc.push([
                            category,
                            Validation.idToName[validation_id],
                            status.toUpperCase(),
                            message,
                        ]);
                }
            );
            return acc;
        }, []);
        const rows = problemRows.concat(validationRows);
        rows.sort();

        const reportTable = Problem.current.problems
            ? Table(
                  t("Validation Failures"),
                  [
                      t("Component Type"),
                      t("Component Name"),
                      t("Condition"),
                      t("Log"),
                  ],
                  rows
              )
            : Problem.current.report_id
                ? null
                : m("h2.text-center", t("Device has not sent a report"));
        const reportButton = Problem.current.report_id
            ? m(
                  "a.pure-button",
                  {
                      href: `/device/${attrs.id}`,
                      oncreate: m.route.link,
                  },
                  t("Show Device Report")
              )
            : null;

        const deviceLocation = Problem.current.location
            ? Table(
                  t("Device Location"),
                  [t("Datacenter"), t("Rack"), t("Role"), t("Unit")],
                  [
                      [
                          Problem.current.location.datacenter.name,
                          Problem.current.location.rack.name,
                          Problem.current.location.rack.role,
                          Problem.current.location.rack.unit,
                      ],
                  ]
              )
            : m("h2.text-center", t("Device has not been assigned a location"));
        const locationButton = Problem.current.location
            ? m(
                  "a.pure-button",
                  {
                      href: `/rack/${Problem.current.location.rack.id}?device=${attrs.id}`,
                      oncreate: m.route.link,
                  },
                  t("Show Device in Rack")
              )
            : null;

        return m(".pure-g", [
            m(".pure-u-1", reportTable),
            m(".pure-u-1.text-center", reportButton),
            m(".pure-u-1", deviceLocation),
            m(".pure-u-1.text-center", locationButton),
        ]);
    },
};

export default {
    selectProblemDevice,
    makeSelection,
    showDevice,
};
