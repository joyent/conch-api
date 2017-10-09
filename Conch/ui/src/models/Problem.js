import m from "mithril";

function sortObject(obj) {
    return Object.keys(obj)
        .sort()
        .reduce((acc, i) => {
            acc[i] = obj[i];
            return acc;
        }, {});
}

const Problem = {
    devices: {},
    current: null,
    loadDeviceProblems() {
        return m
            .request({
                method: "GET",
                url: "/problem",
                withCredentials: true,
            })
            .then(res => {
                Problem.devices = {
                    failing: sortObject(res.failing),
                    unlocated: sortObject(res.unlocated),
                    unreported: sortObject(res.unreported),
                };
            })
            .catch(e => {
                if (e.error === "unauthorized") {
                    m.route.set("/login");
                } else {
                    console.log(`Error in GET /problem: ${e.message}`);
                }
            });
    },
    deviceHasProblem(deviceId) {
        // Search through all categories for a matching deviceId
        return Object.keys(Problem.devices).some(
            group => Problem.devices[group][deviceId]
        );
    },
};

export default Problem;
