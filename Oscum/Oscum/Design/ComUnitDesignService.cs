using System.Collections.Generic;
using Oscum.Service;

namespace Oscum.Design;

public class ComUnitDesignService : ComUnitService
{
    public override List<ICom> GetComs()
    {
        return [
        new DesignCom
        {
            Name = "DesignCom1",
        },
        new DesignCom
        {
            Name = "DesignCom2",
        },
        new DesignCom
        {
            Name = "DesignCom3",
        }];
    }
}