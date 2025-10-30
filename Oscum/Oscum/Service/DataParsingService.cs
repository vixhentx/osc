using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using Avalonia.Threading;
using Kaitai;
using Oscum.Models.Kaitai;

namespace Oscum.Service
{
    /// <summary>
    /// Singleton service to manage serial data buffering, parsing, and event dispatching.
    /// This service ensures that ViewModel updates happen on the UI thread.
    /// </summary>
    public class DataParsingService
    {
        private readonly ComUnitService _comUnitService;
        private readonly List<byte> _byteBuffer = new();
        private ICom? _activeCom;

        // --- Public Events for ViewModels ---
        // These events are dispatched on the UI thread.
        public event Action<FpgaProtocol.RealtimeReportData>? OnRealtimeDataReceived;
        public event Action<FpgaProtocol.TestReportData>? OnTestReportReceived;
        public event Action<FpgaProtocol.SettingsData>? OnSettingsDataReceived;
        // Add events for other frame types as needed (e.g., TestSet)

        public DataParsingService(ComUnitService comUnitService)
        {
            _comUnitService = comUnitService;
            _comUnitService.PropertyChanged += ComUnitService_PropertyChanged;
            SetActiveCom(_comUnitService.CurrentCom);
        }

        private void ComUnitService_PropertyChanged(object? sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == nameof(ComUnitService.CurrentCom))
            {
                SetActiveCom(_comUnitService.CurrentCom);
            }
        }

        private void SetActiveCom(ICom? com)
        {
            if (_activeCom != null)
            {
                _activeCom.DataReceived -= OnDataReceived;
            }

            _activeCom = com;

            if (_activeCom != null)
            {
                _activeCom.DataReceived += OnDataReceived;
            }
            
            // Clear buffer when connection changes
            _byteBuffer.Clear();
        }

        private void OnDataReceived(object? sender, byte[] data)
        {
            // This event comes from a background thread (SerialPort)
            _byteBuffer.AddRange(data);
            ProcessBuffer();
        }

        private void ProcessBuffer()
        {
            // This is still on the background thread
            bool processedAFrame;
            do
            {
                processedAFrame = TryParseFrame();
            } while (processedAFrame);
        }

        private bool TryParseFrame()
        {
            if (_byteBuffer.Count == 0)
                return false;

            try
            {
                // 1. Create a stream from the buffer.
                // We use a copy so the original buffer can be safely modified.
                var bufferCopy = _byteBuffer.ToArray();
                var stream = new KaitaiStream(bufferCopy);
                var protocol = new FpgaProtocol(stream);

                // 2. If parsing succeeds, we know we had at least one full frame.
                // The stream's position tells us how many bytes were consumed.
                long bytesConsumed = stream.Pos;

                // 3. Dispatch the parsed data to the UI thread
                DispatchFrame(protocol);

                // 4. Remove the consumed bytes from the front of the buffer
                _byteBuffer.RemoveRange(0, (int)bytesConsumed);

                // 5. Report success so the loop continues
                return true;
            }
            catch (System.IO.EndOfStreamException)
            {
                // This is the correct exception for incomplete data.
                // We don't have a full frame yet.
                return false;
            }
            catch (Exception ex)
            {
                // This is an unexpected error (e.g., unknown frame header,
                // data corruption, or a bug in the .ksy file).
                Debug.WriteLine($"[DataParsingService] Error parsing frame: {ex.Message}");

                // To prevent an infinite loop of errors, we should clear the buffer
                // or at least remove the offending byte. Clearing is safer.
                _byteBuffer.Clear();
                return false;
            }
        }

        private void DispatchFrame(FpgaProtocol protocol)
        {
            // Use Dispatcher.UIThread.Post to move execution to the UI thread,
            // so ViewModels can update ObservableProperties safely.
            switch (protocol.FrameHeader)
            {
            case FpgaProtocol.FrameType.RealtimeReport:
                if (protocol.Body is FpgaProtocol.RealtimeReportData report)
                {
                    Dispatcher.UIThread.Post(() => OnRealtimeDataReceived?.Invoke(report));
                }
                break;
                
            case FpgaProtocol.FrameType.TestReport:
                if (protocol.Body is FpgaProtocol.TestReportData testReport)
                {
                    Dispatcher.UIThread.Post(() => OnTestReportReceived?.Invoke(testReport));
                }
                break;

            case FpgaProtocol.FrameType.Settings:
                if (protocol.Body is FpgaProtocol.SettingsData settings)
                {
                    Dispatcher.UIThread.Post(() => OnSettingsDataReceived?.Invoke(settings));
                }
                break;
                
            // Add cases for other frame types
            }
        }
    }
}

