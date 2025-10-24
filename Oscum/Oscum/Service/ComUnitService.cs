using System;
using System.Collections.Generic;
using CommunityToolkit.Mvvm.ComponentModel;
using Oscum.Models;

namespace Oscum.Service;

/*
 * 把ComUnit封装成一个Singleton, 用于全局共享
 */
public partial class ComUnitService : ObservableObject
{
    [ObservableProperty]
    public ComUnit? comUnit;

    public virtual List<ICom> GetComs()
    {
        throw new NotImplementedException();
    }
    
}