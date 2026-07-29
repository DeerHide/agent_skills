"""Quick start example for fastapi_factory_utilities."""

from fastapi_factory_utilities.core.app import (
    ApplicationAbstract,
    ApplicationGenericBuilder,
)
from fastapi_factory_utilities.core.plugins import PluginAbstract
from fastapi_factory_utilities.core.plugins.odm_plugin import ODMPlugin


class MyApp(ApplicationAbstract):
    """Example application."""

    PACKAGE_NAME = "my_app"
    ODM_DOCUMENT_MODELS = []

    def configure(self) -> None:
        """Configure routes and middleware."""
        pass

    async def on_startup(self) -> None:
        """Custom startup logic."""
        pass

    async def on_shutdown(self) -> None:
        """Custom shutdown logic."""
        pass


class MyAppBuilder(ApplicationGenericBuilder[MyApp]):
    """Builder for MyApp.

    Base ``ApplicationGenericBuilder`` does not call ``get_default_plugins``;
    wire defaults in ``__init__`` (same pattern as ``example.app.AppBuilder``).
    """

    def get_default_plugins(self) -> list[PluginAbstract]:
        """Return default plugins."""
        return [ODMPlugin()]

    def __init__(self, plugins: list[PluginAbstract] | None = None) -> None:
        """Initialize with default plugins when none are provided."""
        if plugins is None:
            plugins = self.get_default_plugins()
        super().__init__(plugins=plugins)


if __name__ == "__main__":
    MyAppBuilder().build_and_serve()
