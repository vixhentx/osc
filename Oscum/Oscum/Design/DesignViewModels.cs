using Oscum.ViewModels;
using Oscum.Service; // Added

// Added

namespace Oscum.Design
{
    static class ServiceSingleton
    {
        // Create both services
        public static readonly ComUnitDesignService comUnitDesignService = new ();
        // The DataParsingService gets the ComUnitService so it can find the mock port
        public static readonly DataParsingService dataParsingService = new (comUnitDesignService);
        public static readonly CommandService commandService = new (comUnitDesignService);
    }

    // Update constructors to pass both services
    public class ComViewDesignModel() : ComViewModel(ServiceSingleton.comUnitDesignService);
    public class RealTimeViewDesignModel():  RealTimeViewModel(ServiceSingleton.comUnitDesignService, ServiceSingleton.dataParsingService);
    public class SettingViewDesignModel(): SettingViewModel(ServiceSingleton.comUnitDesignService, ServiceSingleton.dataParsingService, ServiceSingleton.commandService);
    public class TestViewDesignModel(): TestViewModel(ServiceSingleton.comUnitDesignService, ServiceSingleton.dataParsingService, ServiceSingleton.commandService);

    public class MainViewDesignModel() : MainViewModel(
        ServiceSingleton.comUnitDesignService,
        new RealTimeViewDesignModel(),
        new TestViewDesignModel(),
        new SettingViewDesignModel(),
        new ComViewDesignModel()
    );
}