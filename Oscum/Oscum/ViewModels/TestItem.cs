using CommunityToolkit.Mvvm.ComponentModel;

namespace Oscum.ViewModels;

public partial class TestItem<T> : ObservableObject
{

    [ObservableProperty]
    private T? target;

    //容差,单位为百分比
    [ObservableProperty]
    private float tolerance = 0.01f;

    [ObservableProperty]
    private bool isPassed = false;
    
}