using System.Diagnostics;
using CommunityToolkit.Mvvm.ComponentModel;
using Oscum.Utils;

namespace Oscum.ViewModels;

public partial class RealTimeViewModel : ViewModelBase
{

	#region 波形显示

	[ObservableProperty]
	public string xAxisName = "";

	[ObservableProperty]
	public string yAxisName = "";
	
	//电压单位
	private static readonly string[] voltageUnitTable = ["mV","V"];

	[ObservableProperty]
	public string voltUnit = "";
	
	//时间单位
	private static readonly string[] timeUnitTable = ["ns","us","ms","s"];
	private static readonly string[] freqUnitTable = ["GHz", "MHz", "KHz", "Hz"];
	
	[ObservableProperty]
	public string timeUnit = "";

	[ObservableProperty]
	public string freqUnit = "";
	
	//每一格的时间跨度,单位ns
	[ObservableProperty]
	public double gridXScale;
	partial void OnGridXScaleChanged(double value)
	{
		Debug.Assert(timeUnitTable.Length == freqUnitTable.Length);
		
		(double showVale, int index) = UnitUtils.AutoAdaptUnit(value, timeUnitTable.Length);
		TimeUnit = timeUnitTable[index];
		FreqUnit = freqUnitTable[index];
		XAxisName = $"时间/{showVale}";
	}

	//每一格的电压跨度,单位mV
	[ObservableProperty]
	public double gridYScale;
	partial void OnGridYScaleChanged(double value)
	{
		(double showValue, int index) = UnitUtils.AutoAdaptUnit(value, timeUnitTable.Length);
		VoltUnit = voltageUnitTable[index];
		YAxisName = $"电压/{showValue}";
	}

	#endregion
	
	#region 波形参数

	[ObservableProperty]
	public double volt;

	[ObservableProperty]
	public double freq;

	[ObservableProperty]
	public double period;

	[ObservableProperty]
	public double duty;

	[ObservableProperty]
	public double amp;


	#endregion

}