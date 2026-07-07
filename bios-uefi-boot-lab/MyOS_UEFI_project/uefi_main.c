// uefi_main.c
// MyOS UEFI progress bar version

typedef unsigned long long UINTN;
typedef unsigned long long UINT64;
typedef unsigned int       UINT32;
typedef unsigned short     CHAR16;
typedef void*              EFI_HANDLE;
typedef UINT64             EFI_STATUS;

#define EFI_SUCCESS 0

#if defined(__x86_64__)
#define EFIAPI __attribute__((ms_abi))
#else
#define EFIAPI
#endif

typedef struct {
    UINT64 Signature;
    UINT32 Revision;
    UINT32 HeaderSize;
    UINT32 CRC32;
    UINT32 Reserved;
} EFI_TABLE_HEADER;

struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL;

typedef EFI_STATUS (EFIAPI *EFI_TEXT_STRING)(
    struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *This,
    CHAR16 *String
);

typedef EFI_STATUS (EFIAPI *EFI_TEXT_SET_ATTRIBUTE)(
    struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *This,
    UINTN Attribute
);

typedef EFI_STATUS (EFIAPI *EFI_TEXT_CLEAR_SCREEN)(
    struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *This
);

typedef EFI_STATUS (EFIAPI *EFI_TEXT_SET_CURSOR_POSITION)(
    struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *This,
    UINTN Column,
    UINTN Row
);

typedef struct EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL {
    void *Reset;
    EFI_TEXT_STRING OutputString;
    void *TestString;
    void *QueryMode;
    void *SetMode;
    EFI_TEXT_SET_ATTRIBUTE SetAttribute;
    EFI_TEXT_CLEAR_SCREEN ClearScreen;
    EFI_TEXT_SET_CURSOR_POSITION SetCursorPosition;
    void *EnableCursor;
    void *Mode;
} EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL;

typedef struct {
    EFI_TABLE_HEADER Hdr;
    CHAR16 *FirmwareVendor;
    UINT32 FirmwareRevision;

    EFI_HANDLE ConsoleInHandle;
    void *ConIn;

    EFI_HANDLE ConsoleOutHandle;
    EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *ConOut;

    EFI_HANDLE StandardErrorHandle;
    EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *StdErr;

    void *RuntimeServices;
    void *BootServices;

    UINTN NumberOfTableEntries;
    void *ConfigurationTable;
} EFI_SYSTEM_TABLE;

static EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL *ConOut;

static void print(CHAR16 *s) {
    ConOut->OutputString(ConOut, s);
}

static void set_color(UINTN color) {
    ConOut->SetAttribute(ConOut, color);
}

static void delay(void) {
    volatile UINT64 i;

    for (i = 0; i < 80000000ULL; i++) {
    }
}

static void print_number_3_digits(int value) {
    CHAR16 buf[4];

    buf[0] = (CHAR16)(L'0' + value / 100);
    buf[1] = (CHAR16)(L'0' + (value / 10) % 10);
    buf[2] = (CHAR16)(L'0' + value % 10);
    buf[3] = 0;

    if (value < 100) {
        buf[0] = L' ';
    }

    if (value < 10) {
        buf[1] = L' ';
    }

    print(buf);
}

static void draw_progress_bar(int progress) {
    int i;
    int percent;

    percent = progress * 5;

    ConOut->SetCursorPosition(ConOut, 0, 6);

    set_color(0x0F);
    print((CHAR16*)L"[");

    for (i = 0; i < 20; i++) {
        if (i < progress) {
            set_color(0x0A);
            print((CHAR16*)L"#");
        } else {
            set_color(0x08);
            print((CHAR16*)L"-");
        }
    }

    set_color(0x0F);
    print((CHAR16*)L"]  ");

    print_number_3_digits(percent);
    print((CHAR16*)L"%");
}

EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
    int i;

    (void)ImageHandle;

    ConOut = SystemTable->ConOut;

    ConOut->ClearScreen(ConOut);

    set_color(0x0A);
    print((CHAR16*)L"==================== MyOS UEFI Boot Loader ====================\r\n\r\n");

    set_color(0x0F);
    print((CHAR16*)L"Running under UEFI mode.\r\n");
    print((CHAR16*)L"Loading MyOS kernel demo...\r\n\r\n");

    for (i = 0; i <= 20; i++) {
        draw_progress_bar(i);
        delay();
    }

    print((CHAR16*)L"\r\n\r\n");

    set_color(0x0A);
    print((CHAR16*)L"Boot Complete!\r\n");

    set_color(0x0F);
    print((CHAR16*)L"\r\nThis is not BIOS anymore. This program is loaded directly by UEFI firmware.\r\n");
    print((CHAR16*)L"Press power button or reboot manually.\r\n");

    while (1) {
    }

    return EFI_SUCCESS;
}