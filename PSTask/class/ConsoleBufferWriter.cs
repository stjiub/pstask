using System;
using System.Runtime.InteropServices;

public class ConsoleBufferWriter
{
    [StructLayout(LayoutKind.Sequential)]
    public struct COORD
    {
        public short X;
        public short Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct CHAR_INFO
    {
        public ushort UnicodeChar;
        public short Attributes;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct SMALL_RECT
    {
        public short Left;
        public short Top;
        public short Right;
        public short Bottom;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct CONSOLE_SCREEN_BUFFER_INFO
    {
        public COORD dwSize;
        public COORD dwCursorPosition;
        public short wAttributes;
        public SMALL_RECT srWindow;
        public COORD dwMaximumWindowSize;
    }

    const int STD_OUTPUT_HANDLE = -11;

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetStdHandle(int nStdHandle);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool WriteConsoleOutput(IntPtr hConsoleOutput, [In] CHAR_INFO[] lpBuffer, COORD dwBufferSize, COORD dwBufferCoord, ref SMALL_RECT lpWriteRegion);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetConsoleOutputCP(uint wCodePageID);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool GetConsoleScreenBufferInfo(IntPtr hConsoleOutput, out CONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo);

    // Enum for console colors
    public enum ConsoleColor
    {
        Black = 0,
        DarkBlue = 1,
        DarkGreen = 2,
        DarkCyan = 3,
        DarkRed = 4,
        DarkMagenta = 5,
        DarkYellow = 6,
        Gray = 7,
        DarkGray = 8,
        Blue = 9,
        Green = 10,
        Cyan = 11,
        Red = 12,
        Magenta = 13,
        Yellow = 14,
        White = 15
    }

    public static void WriteTextAtPosition(string text, int x, int y, ConsoleColor foregroundColor)
    {
        IntPtr hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
        
        // Get current console attributes
        CONSOLE_SCREEN_BUFFER_INFO csbi;
        GetConsoleScreenBufferInfo(hConsole, out csbi);
        
        // Extract current background color (bits 4-7)
        short currentBackground = (short)(csbi.wAttributes & 0xF0);
        
        // Combine current background with new foreground color
        short attributes = (short)(currentBackground | (short)foregroundColor);

        // Ensure the console is using a Unicode code page (UTF-8)
        SetConsoleOutputCP(65001);

        CHAR_INFO[] buffer = new CHAR_INFO[text.Length];
        for (int i = 0; i < text.Length; i++)
        {
            buffer[i].UnicodeChar = text[i];
            buffer[i].Attributes = attributes;  // Use combined attributes
        }

        COORD bufferSize = new COORD { X = (short)text.Length, Y = 1 };
        COORD bufferCoord = new COORD { X = 0, Y = 0 };
        SMALL_RECT writeRegion = new SMALL_RECT
        {
            Left = (short)x,
            Top = (short)y,
            Right = (short)(x + text.Length - 1),
            Bottom = (short)y
        };

        WriteConsoleOutput(hConsole, buffer, bufferSize, bufferCoord, ref writeRegion);
    }
}