using System;
using System.Threading.Tasks;

namespace Oscum.Service;

public interface ICom : IDisposable
{
    string Type { get; }
    string Name { get; }
    bool IsRunning { get; }
    void Open();
    void Close();
    event EventHandler<byte[]> DataReceived;
    Task SendAsync(byte[] data); 
}