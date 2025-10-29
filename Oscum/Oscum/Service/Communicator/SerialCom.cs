using System;
using System.Diagnostics;
using System.IO.Ports;
using System.Threading.Tasks;

namespace Oscum.Service;

public class SerialCom : ICom
{

    private SerialPort? serialPort;
    public required int BaudRate { get; set; }
    public required string Name { get; set; }

    public bool IsRunning { get; private set; }


    public void Open()
    {
        if (IsRunning) return;
        serialPort = new()
        {
            PortName = Name,
            BaudRate = BaudRate,
            Parity = Parity.None,
            DataBits = 8,
            StopBits = StopBits.One
        };
        serialPort.DataReceived += OnDataReceived;
        try
        {
            serialPort.Open();
            IsRunning = true;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Error: opening serial port: {ex.Message}");
            throw;
        }
    }
    public void Close()
    {
        try
        {
            if(!IsRunning) return;
            serialPort!.Close();
            serialPort.DataReceived -= OnDataReceived;
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Error: closing serial port: {ex.Message}");
            throw;
        }
    }

    public event EventHandler<byte[]>? DataReceived;

    public async Task SendAsync(byte[] data)
    {
        if (IsRunning && serialPort != null)
        {
            await serialPort.BaseStream.WriteAsync(data);
        }
    }
    private void OnDataReceived(object sender, SerialDataReceivedEventArgs e)
    {
        try
        {
            int bytesToRead = serialPort!.BytesToRead;
            if (bytesToRead > 0)
            {
                byte[] buffer = new byte[bytesToRead];
                int bytesRead = serialPort.Read(buffer, 0, bytesToRead);

                if (bytesRead < bytesToRead) Array.Resize(ref buffer, bytesRead);

                DataReceived?.Invoke(this, buffer);
            }
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"Error: reading serial data: {ex.Message}");
        }
    }
    public void Dispose() => serialPort?.Dispose();
    public string Type => $"Serial@{BaudRate}bps";
}