import m from "mithril";

const ValidationPlan = {
    list: [],
    idToName: {},
    load() {
        return m
            .request({
                method: "get",
                url: "/validation_plan",
            })
            .then(validations => {
                ValidationPlan.list = validations;
                ValidationPlan.idToName = validations.reduce(
                    (acc, { id, name }) => {
                        acc[id] = name;
                        return acc;
                    },
                    {}
                );
            });
    },
};

export default ValidationPlan;
