import m from "mithril";

const ValidationState = {
    currentList: [],

    loadForWorkspace(wId) {
        return m
            .request({
                method: "get",
                url: `/workspace/${wId}/validation_state`,
            })
            .then(validationStates => {
                ValidationState.currentList = validationStates;
            });
    },

    loadForDevice(dId) {
        return m
            .request({
                method: "get",
                url: `/device/${dId}/validation_state`,
            })
            .then(validationStates => {
                ValidationState.currentList = validationStates;
            });
    },
};

export default ValidationState;
