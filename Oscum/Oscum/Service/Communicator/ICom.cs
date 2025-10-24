using System;

namespace Oscum.Service;

public interface ICom : IDisposable
{
    string Type { get; }
    string Name { get; }
    bool IsOpen { get; }
    void Open();
    void Close();
    event EventHandler<byte[]> DataReceived;
    void Send(byte[] data); 
}