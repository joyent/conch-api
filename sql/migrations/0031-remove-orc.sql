SELECT run_migration(31, $$
	drop table workflow_step_status;
	drop table workflow_step;
	drop table workflow_status;
	drop table workflow_lifecycle_plan;

	drop table workflow;
	drop table workflow_lifecycle;

	drop type e_workflow_status;
	drop type e_workflow_step_state;

	drop type e_workflow_validation_status;
$$);

