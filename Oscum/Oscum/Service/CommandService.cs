using Oscum.Models;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;
using Oscum.Models.Kaitai;

namespace Oscum.Service;

/// <summary>
/// Service responsible for serializing and sending commands to the device.
/// </summary>
public class CommandService(ComUnitService comUnitService)
{

    /// <summary>
    /// Sends a single setting item to the device.
    /// </summary>
    public async Task SendSettingAsync(SettingItem[] settings)
    {
        using MemoryStream ms = new();
        await using BinaryWriter writer = new(ms);
        writer.Write((byte) FpgaProtocol.FrameType.Settings);
        foreach (var item in settings)
        {
            writer.Write((byte)item.Id);
            writer.Write((byte)item.NewValue);
        }
        await SendPacketAsync(ms.ToArray());
    }

    /// <summary>
    /// Sends a single test item to the device.
    /// </summary>
    public async Task SendTestItemAsync(TestItem[] tests)
    {
        using  MemoryStream ms = new();
        await using BinaryWriter writer = new(ms);
        writer.Write((byte) FpgaProtocol.FrameType.TestSet);
        foreach (var item in tests)
        {
            writer.Write((byte)item.Id);
            writer.Write((byte)item.Tolerance);
            writer.Write((byte)item.Target);
        }

        await SendPacketAsync(ms.ToArray());
    }

    /// <summary>
    /// Private helper to get the current port and send data.
    /// </summary>
    private async Task SendPacketAsync(byte[] packet)
    {
        var com = comUnitService.CurrentCom;
        if (com == null || !com.IsRunning)
        {
            Debug.WriteLine("CommandService: No active connection to send packet.");
            // Optionally, show a user-facing error here
            return;
        }

        try
        {
            await com.SendAsync(packet);
            Debug.WriteLine($"CommandService: Sent {packet.Length} bytes.");
        }
        catch (System.Exception ex)
        {
            Debug.WriteLine($"CommandService: Error sending packet: {ex.Message}");
            // Optionally, show a user-facing error
        }
    }
}
