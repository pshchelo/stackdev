from heat.engine import properties
from heat.engine import resource


class StuckCreate(resource.Resource):
    """A test resource that can be deleted but takes forever to create."""

    properties_schema = {}

    def handle_create(self):
        return

    def check_create_complete(self, data):
        return False

    def handle_delete(self):
        return


class StuckUpdate(resource.Resource):
    """A test resource that takes forever to update."""

    PROPERTIES = (
        DATA,
    ) = (
        'data',
    )

    properties_schema = {
        DATA: properties.Schema(
            properties.Schema.STRING,
            "Dummy text data",
            default="",
            update_allowed=True
        )
    }

    def handle_create(self):
        return

    def handle_update(self, json_snippet, tmpl_diff, prop_diff):
        return

    def check_update_complete(self, data):
        return False

    def handle_delete(self):
        return


def resource_mapping():
    return {
        "OS::Test::StuckCreate": StuckCreate,
        "OS::Test::StuckUpdate": StuckUpdate
    }
