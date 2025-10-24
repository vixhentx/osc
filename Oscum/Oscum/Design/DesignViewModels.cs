using Oscum.ViewModels;

namespace Oscum.Design;

static class ServiceSingleton
{
    public static readonly ComUnitDesignService comUnitDesignService = new ();
};
public class ComViewDesignModel(): ComViewModel(ServiceSingleton.comUnitDesignService);
public class RealTimeViewDesignModel():  RealTimeViewModel(ServiceSingleton.comUnitDesignService);
public class SettingViewDesignModel(): SettingViewModel(ServiceSingleton.comUnitDesignService);
public class TestViewDesignModel(): TestViewModel(ServiceSingleton.comUnitDesignService);

public class MainViewDesignModel(): MainViewModel(new ComUnitDesignService(),new RealTimeViewDesignModel(),new TestViewDesignModel(),new SettingViewDesignModel(),new ComViewDesignModel());