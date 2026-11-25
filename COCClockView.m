#import <objc/message.h>
#import <dlfcn.h>
#import <string.h>
#import <math.h>
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import "COCClockView.h"
#import "Prefs.h"

static NSString *const COCWeatherUpdated = @"COCWeatherUpdated";

#pragma mark - Шрифт для виджетов

static UIFont *COCRounded(CGFloat size, UIFontWeight weight) {
    UIFont *f = [UIFont systemFontOfSize:size weight:weight];
    UIFontDescriptor *d = [f.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
    return d ? [UIFont fontWithDescriptor:d size:size] : f;
}

#pragma mark - Собственные цифры (оригинальный набор ColorOS, трассировка с листа 0–9)
//
// Нативные размеры: чаша цифры 68 x 472 (y вниз), шаг между цифрами 91.
// «4», «2», «7» чуть выступают за ячейку, поэтому вид с цифрами имеет поля COC_PADX / COC_PADY.
// Таблицы ниже сгенерированы из листа цифр скриптом vectorize.py — вручную не править.
//
// Растяжение по горизонтали относительно нативных пропорций (1.0 = как на листе):
//   COC_STRETCH_FULL    — «во всю ширину» и вертикальные цифры слева
//   COC_STRETCH_COMPACT — компактный вариант с виджетами сбоку, чуть шире
//



typedef struct { float x, y; } COCPt;

// AUTO-GENERATED (vectorize.py + gen_tables.py) — не править вручную

static const COCPt kG0_0[] = {
    {42.6,470.91}, {33.6,471.66}, {25.6,470.96}, {21.6,469.93}, {18.6,468.84}, {14.6,466.89}, {11.6,464.9}, {8.6,462.2},
    {6.32,459.7}, {4.22,456.7}, {2.19,452.7}, {0.38,446.7}, {-0.19,439.7}, {-0.2,32.7}, {0.11,26.7}, {0.38,24.7},
    {1.43,20.7}, {2.19,18.7}, {4.22,14.7}, {7.18,10.7}, {11.6,6.5}, {16.6,3.43}, {21.6,1.47}, {26.6,0.28},
    {33.6,-0.26}, {41.6,0.31}, {46.6,1.55}, {51.6,3.57}, {54.6,5.27}, {57.6,7.49}, {60.82,10.7}, {63.04,13.7},
    {64.84,16.7}, {67.04,22.7}, {67.85,26.7}, {68.11,30.7}, {68.3,438.7}, {68.11,443.7}, {67.91,445.7}, {66.98,449.7},
    {65.94,452.7}, {63.9,456.7}, {61.77,459.7}, {60.02,461.7}, {56.6,464.76}, {51.6,467.88}, {46.6,469.87}
};
static const COCPt kG0_1[] = {
    {35.67,448.7}, {38.6,447.85}, {40.15,446.7}, {41.9,444.7}, {43.07,441.7}, {43.46,437.7}, {43.46,34.7}, {43.32,31.7},
    {42.83,28.7}, {41.9,26.7}, {41.11,25.7}, {38.6,23.53}, {35.6,22.65}, {33.6,22.5}, {29.6,23.45}, {27.97,24.7},
    {26.6,26.22}, {25.27,28.7}, {24.58,33.7}, {24.57,436.7}, {24.64,438.7}, {25.27,442.7}, {26.22,444.7}, {27.6,446.33},
    {29.6,447.93}, {30.6,448.24}, {33.6,448.88}
};
static const COCPt kG1_0[] = {
    {66.6,467.32}, {2.6,467.46}, {1.6,467.32}, {0.91,466.7}, {0.63,465.7}, {0.63,446.7}, {0.66,445.7}, {1.06,444.7},
    {1.6,444.24}, {2.6,444.16}, {22.6,444.16}, {23.07,443.7}, {23.11,442.7}, {23.11,28.7}, {22.6,27.54}, {4.6,27.54},
    {3.6,27.47}, {2.42,26.7}, {2.23,25.7}, {2.24,5.7}, {2.84,4.7}, {3.6,4.22}, {45.6,4.19}, {46.6,4.24},
    {47.24,4.7}, {47.83,5.7}, {47.86,442.7}, {47.92,443.7}, {48.6,444.16}, {65.6,444.16}, {66.6,444.24}, {67.15,444.7},
    {67.57,445.7}, {67.6,446.7}, {67.6,465.7}, {67.3,466.7}
};
static const COCPt kG2_0[] = {
    {74.6,468.97}, {73.6,469.42}, {72.6,469.46}, {6.6,469.46}, {4.6,469.1}, {4.23,468.7}, {4.09,467.7}, {4.26,446.7},
    {4.89,443.7}, {5.32,439.7}, {6.87,430.7}, {9.29,413.7}, {9.92,410.7}, {12.33,393.7}, {13.88,384.7}, {18.28,354.7},
    {18.91,351.7}, {23.31,321.7}, {23.94,318.7}, {27.27,295.7}, {27.9,292.7}, {32.3,262.7}, {32.93,259.7}, {35.35,242.7},
    {35.82,240.7}, {37.33,229.7}, {39.94,213.7}, {42.91,189.7}, {43.81,176.7}, {44,168.7}, {44.01,35.7}, {43.66,32.7},
    {43.07,30.7}, {42.05,28.7}, {39.6,26.28}, {37.6,25.35}, {35.6,25.12}, {32.6,25.19}, {31.6,25.33}, {29.6,26.23},
    {27.6,27.98}, {26.3,29.7}, {25.27,32.7}, {25.07,36.7}, {24.95,199.7}, {24.6,200.09}, {23.6,200.52}, {22.6,200.57},
    {1.6,200.52}, {0.26,199.7}, {0.14,198.7}, {0.22,31.7}, {1.16,25.7}, {2.35,21.7}, {4.26,17.7}, {6.26,14.7},
    {8.6,12.06}, {12.6,8.44}, {17.6,5.55}, {23.6,3.36}, {28.6,2.36}, {34.6,2.11}, {41.6,2.53}, {45.6,3.38},
    {48.6,4.35}, {54.6,7.26}, {58.6,10.23}, {62.73,14.7}, {65.79,19.7}, {67,22.7}, {67.89,25.7}, {68.79,31.7},
    {68.92,34.7}, {68.92,166.7}, {68.74,175.7}, {67.92,188.7}, {65.91,203.7}, {28.3,445.7}, {28.6,446}, {29.6,446.16},
    {73.6,446.18}, {74.56,446.7}, {75.03,447.7}, {75.04,467.7}, {74.86,468.7}
};
static const COCPt kG3_0[] = {
    {42.6,470.98}, {34.6,471.66}, {26.6,471.07}, {22.6,470.12}, {19.6,469.11}, {13.6,466.08}, {10.6,463.78}, {8.38,461.7},
    {5.21,457.7}, {3.43,454.7}, {1.18,448.7}, {0.37,444.7}, {0.1,440.7}, {0.08,302.7}, {0.09,301.7}, {0.6,300.8},
    {1.6,300.28}, {23.6,300.3}, {24.97,301.7}, {25.15,440.7}, {26.11,443.7}, {27.3,445.7}, {28.6,446.98}, {30.6,448.12},
    {34.6,448.71}, {38.6,447.92}, {41.31,445.7}, {42.7,443.7}, {43.09,442.7}, {43.9,438.7}, {43.86,259.7}, {43.04,255.7},
    {42.11,253.7}, {40.6,251.56}, {37.6,249.36}, {33.6,248.3}, {16.6,248.06}, {16.23,247.7}, {15.93,245.7}, {15.93,223.7},
    {15.97,222.7}, {16.48,221.7}, {17.6,221.3}, {33.6,221.22}, {35.6,220.95}, {37.6,220.18}, {39.6,219.04}, {41.73,216.7},
    {43.08,213.7}, {43.86,209.7}, {43.92,33.7}, {43.75,31.7}, {43.01,28.7}, {41.98,26.7}, {39.6,24.34}, {37.6,23.4},
    {35.6,23.14}, {32.6,23.17}, {31.6,23.28}, {29.6,24.17}, {27.6,25.82}, {26.21,27.7}, {25.42,29.7}, {25.09,31.7},
    {24.92,170.7}, {23.6,171.88}, {22.6,171.94}, {1.6,171.92}, {0.6,171.35}, {0.12,170.7}, {0.08,169.7}, {0.08,32.7},
    {0.43,26.7}, {1.25,22.7}, {2.23,19.7}, {4.17,15.7}, {5.43,13.7}, {7.6,11.03}, {9.87,8.7}, {12.6,6.35},
    {17.6,3.45}, {23.6,1.31}, {28.6,0.34}, {32.6,0.14}, {39.6,0.29}, {45.6,1.44}, {48.6,2.42}, {52.6,4.23},
    {54.6,5.32}, {58.6,8.32}, {61.86,11.7}, {64,14.7}, {66.07,18.7}, {66.9,20.7}, {67.98,24.7}, {68.78,32.7},
    {68.69,207.7}, {67.91,214.7}, {66.84,218.7}, {65.05,222.7}, {63.88,224.7}, {60.6,228.55}, {58.29,230.7}, {56.6,232.09},
    {52.14,234.7}, {53.6,235.95}, {54.6,236.35}, {57.6,238.39}, {59.1,239.7}, {62.03,242.7}, {64.08,245.7}, {66.92,251.7},
    {67.97,255.7}, {68.65,261.7}, {68.71,440.7}, {68.03,446.7}, {66.99,450.7}, {64.81,455.7}, {62.06,459.7}, {57.6,464.2},
    {53.6,467.02}, {49.6,468.93}, {46.6,469.98}
};
static const COCPt kG4_0[] = {
    {58.6,469.32}, {37.6,469.37}, {36.6,469.33}, {35.43,468.7}, {35.17,466.7}, {35.17,394.7}, {34.6,394.13}, {-6.4,394.13},
    {-7.4,394.04}, {-8.42,392.7}, {-8.48,370.7}, {-7.7,359.7}, {-5.08,327.7}, {-1.65,280.7}, {-1.1,275.7}, {-0.66,267.7},
    {-0.1,262.7}, {0.33,254.7}, {2.88,223.7}, {3.32,215.7}, {5.86,184.7}, {6.3,176.7}, {6.86,171.7}, {8.29,150.7},
    {10.91,118.7}, {11.28,111.7}, {12.91,92.7}, {15.34,58.7}, {15.89,53.7}, {16.33,45.7}, {16.89,40.7}, {19.32,6.7},
    {19.55,4.7}, {20.06,3.7}, {20.6,3.25}, {58.6,3.22}, {59.33,3.7}, {59.93,4.7}, {59.95,369.7}, {60.6,370.64},
    {74.6,370.64}, {75.6,370.8}, {76.71,371.7}, {76.88,372.7}, {76.88,391.7}, {76.83,392.7}, {75.6,394.07}, {60.6,394.13},
    {59.95,394.7}, {59.94,467.7}, {59.6,468.7}
};
static const COCPt kG4_1[] = {
    {35.97,369.7}, {37.51,68.7}, {37.6,46.2}, {15.11,369.7}, {15.6,370.64}, {16.6,370.64}, {34.6,370.64}, {35.6,370.4}
};
static const COCPt kG5_0[] = {
    {43.6,468.61}, {35.6,469.35}, {27.6,468.82}, {22.6,467.63}, {17.6,465.66}, {15.6,464.59}, {12.6,462.59}, {9.6,459.88},
    {7.34,457.4}, {5.24,454.4}, {3.21,450.4}, {2.5,448.4}, {1.43,444.4}, {1.13,442.4}, {0.8,435.4}, {0.8,312.4},
    {0.87,311.4}, {1.45,310.4}, {2.6,310.04}, {23.6,310.04}, {24.6,310.19}, {25.5,311.4}, {25.6,434.4}, {26.35,440.4},
    {27.29,442.4}, {28.1,443.4}, {29.6,444.84}, {30.6,445.43}, {31.6,445.87}, {34.6,446.4}, {38.6,445.85}, {40.6,444.8},
    {42.81,442.4}, {44.04,439.4}, {44.46,434.4}, {44.45,207.4}, {43.94,202.4}, {43.06,200.4}, {41.6,198.43}, {39.6,196.9},
    {37.6,196.07}, {34.6,195.89}, {32.6,196.07}, {30.6,196.88}, {28.6,198.1}, {27.35,199.4}, {26.16,201.4}, {25.46,203.4},
    {25.14,205.4}, {25.12,239.4}, {24.6,240.66}, {23.6,240.95}, {2.6,240.96}, {1.6,240.9}, {0.94,240.4}, {0.46,239.4},
    {0.44,4.4}, {0.47,3.4}, {1.02,2.4}, {1.6,1.95}, {67.6,1.89}, {68.6,1.94}, {69.21,2.4}, {69.77,3.4},
    {69.8,23.4}, {69.49,24.4}, {68.6,25.12}, {26.6,25.24}, {25.6,25.29}, {25.12,26.4}, {25.12,177.4}, {25.6,178.51},
    {27.6,177.05}, {29.6,175.95}, {33.6,174.24}, {37.6,173.26}, {40.6,172.94}, {44.6,172.94}, {47.6,173.24}, {51.6,174.13},
    {54.6,175.32}, {56.6,176.4}, {59.36,178.4}, {61.6,180.6}, {63.83,183.4}, {64.99,185.4}, {66.75,189.4}, {67.94,193.4},
    {68.79,198.4}, {69.05,201.4}, {69.3,435.4}, {69.01,442.4}, {67.94,447.4}, {65.95,452.4}, {64.82,454.4}, {60.95,459.4},
    {58.6,461.64}, {55.6,463.84}, {52.6,465.54}, {47.6,467.55}
};
static const COCPt kG6_0[] = {
    {42.6,470.65}, {34.6,471.35}, {26.6,470.8}, {22.6,469.85}, {19.6,468.83}, {16.6,467.51}, {13.6,465.82}, {10.6,463.61},
    {7.33,460.4}, {4.36,456.4}, {3.23,454.4}, {1.23,449.4}, {0.3,445.4}, {-0.07,439.4}, {-0.08,33.4}, {0.12,27.4},
    {0.36,25.4}, {1.32,21.4}, {3.37,16.4}, {5.21,13.4}, {9.6,8.36}, {13.6,5.21}, {15.6,4.04}, {19.6,2.24},
    {22.6,1.23}, {27.6,0.14}, {31.6,-0.15}, {39.6,0.01}, {45.6,1.23}, {48.6,2.24}, {52.6,4.03}, {54.6,5.21},
    {58.6,8.36}, {62.97,13.4}, {64.77,16.4}, {65.66,18.4}, {66.79,21.4}, {67.92,26.4}, {68.19,31.4}, {68.2,171.4},
    {68.03,172.4}, {67.6,172.84}, {66.6,173.03}, {45.6,173.04}, {44.6,172.94}, {43.98,172.4}, {43.67,171.4}, {43.66,34.4},
    {43.08,29.4}, {42.8,28.4}, {41.74,26.4}, {39.6,24.19}, {37.6,23.18}, {36.6,22.94}, {31.6,22.95}, {30.6,23.22},
    {28.6,24.31}, {27.35,25.4}, {26.6,26.49}, {25.2,29.4}, {24.78,33.4}, {24.76,203.4}, {25.6,204.2}, {27.6,203},
    {31.6,201.15}, {35.6,200.04}, {41.6,199.65}, {46.6,199.92}, {48.6,200.27}, {51.6,201.11}, {55.6,203}, {58.6,205.11},
    {60.91,207.4}, {63.07,210.4}, {64.76,213.4}, {66.91,219.4}, {67.85,224.4}, {68.09,227.4}, {68.42,438.4}, {68,445.4},
    {66.77,450.4}, {65.07,454.4}, {63.99,456.4}, {61.9,459.4}, {59.6,461.9}, {56.6,464.59}, {51.6,467.64}, {46.6,469.61}
};
static const COCPt kG6_1[] = {
    {38.65,447.4}, {40.13,446.4}, {41.96,444.4}, {42.93,442.4}, {43.65,437.4}, {43.64,233.4}, {42.95,228.4}, {42,226.4},
    {41.19,225.4}, {39.6,223.91}, {38.6,223.3}, {37.6,222.94}, {34.6,222.59}, {30.6,223.12}, {28.6,224.26}, {27.34,225.4},
    {26.07,227.4}, {25.19,229.4}, {24.76,234.4}, {24.77,437.4}, {25.41,442.4}, {26.35,444.4}, {28.6,446.81}, {30.6,447.87},
    {33.6,448.4}, {37.6,447.88}
};
static const COCPt kG7_0[] = {
    {32.6,466.53}, {31.6,467.1}, {30.6,467.16}, {9.6,467.13}, {8.6,466.82}, {8.21,466.4}, {8.12,465.4}, {46.17,28.4},
    {45.6,27.24}, {-5.4,27.12}, {-6.32,26.4}, {-6.62,25.4}, {-6.62,10.4}, {-6.59,5.4}, {-6.01,4.4}, {-5.4,3.94},
    {69.6,3.9}, {70.61,4.4}, {71.07,5.4}, {71.09,24.4}, {70.89,28.4}, {68.29,56.4}, {67.94,62.4}, {66.29,79.4},
    {64.9,97.4}, {64.3,102.4}, {62.91,120.4}, {62.3,125.4}, {61.87,132.4}, {59.27,160.4}, {58.92,166.4}, {58.31,171.4},
    {57.88,178.4}, {56.32,194.4}, {52.94,235.4}, {52.33,240.4}, {51.9,247.4}, {51.29,252.4}, {49.9,270.4}, {49.3,275.4},
    {46.87,305.4}, {44.27,333.4}, {43.92,339.4}, {41.32,367.4}, {40.88,374.4}, {38.28,402.4}, {35.85,432.4}, {35.33,436.4},
    {33.86,455.4}, {33.34,459.4}, {32.98,465.4}
};
static const COCPt kG8_0[] = {
    {42.6,470.61}, {33.6,471.36}, {25.6,470.66}, {21.6,469.63}, {18.6,468.54}, {14.6,466.59}, {11.6,464.6}, {8.6,461.9},
    {6.32,459.4}, {4.22,456.4}, {2.19,452.4}, {0.38,446.4}, {-0.19,439.4}, {-0.2,264.4}, {0.14,257.4}, {1.52,251.4},
    {2.23,249.4}, {4.32,245.4}, {8.6,240.24}, {12.6,236.97}, {15.32,235.4}, {16.52,234.4}, {13.6,232.75}, {10.6,230.67},
    {7.6,227.9}, {5.5,225.4}, {4.18,223.4}, {2.19,219.4}, {1.15,216.4}, {0.13,211.4}, {-0.2,204.4}, {-0.2,33.4},
    {0.14,26.4}, {1.22,21.4}, {3.26,16.4}, {4.43,14.4}, {7.46,10.4}, {9.6,8.21}, {13.6,5.13}, {19.6,2.18},
    {22.6,1.19}, {27.6,0.12}, {31.6,-0.15}, {39.6,0.02}, {45.6,1.27}, {50.6,3.07}, {52.6,4.05}, {55.6,5.95},
    {58.6,8.36}, {63,13.4}, {65.79,18.4}, {66.9,21.4}, {67.85,25.4}, {68.28,31.4}, {68.3,204.4}, {68.03,211.4},
    {67.03,216.4}, {66.02,219.4}, {62.88,225.4}, {60.6,228.06}, {57.6,230.84}, {51.88,234.4}, {52.99,235.4}, {54.6,236.24},
    {58.6,239.19}, {60.84,241.4}, {63.93,245.4}, {65.97,249.4}, {66.99,252.4}, {68.01,257.4}, {68.3,264.4}, {68.3,438.4},
    {68.11,443.4}, {67.91,445.4}, {66.98,449.4}, {65.94,452.4}, {63.9,456.4}, {61.77,459.4}, {60.02,461.4}, {56.6,464.46},
    {51.6,467.58}, {46.6,469.57}
};
static const COCPt kG8_1[] = {
    {37.74,220.4}, {40.6,218.58}, {42.11,216.4}, {42.99,214.4}, {43.45,210.4}, {43.46,34.4}, {43.02,29.4}, {42.14,27.4},
    {40.86,25.4}, {39.6,24.3}, {37.6,23.23}, {36.6,22.96}, {33.6,22.8}, {30.6,23.17}, {28.6,24.19}, {27.26,25.4},
    {25.42,28.4}, {24.6,33.4}, {24.59,210.4}, {25.47,215.4}, {27.31,218.4}, {28.6,219.5}, {30.6,220.56}, {31.6,220.84},
    {35.6,220.92}
};
static const COCPt kG8_2[] = {
    {33.85,448.4}, {37.6,447.85}, {39.6,446.8}, {40.6,445.89}, {41.86,444.4}, {42.82,442.4}, {43.41,438.4}, {43.46,259.4},
    {42.94,254.4}, {42.05,252.4}, {40.6,250.55}, {38.6,248.95}, {36.6,248.17}, {33.6,247.93}, {31.6,248.13}, {29.6,248.92},
    {27.59,250.4}, {26.1,252.4}, {25.18,254.4}, {24.6,258.4}, {24.57,436.4}, {24.63,438.4}, {25.29,442.4}, {26.25,444.4},
    {28.05,446.4}, {29.6,447.5}, {30.6,447.89}
};
static const COCPt kG9_0[] = {
    {42.6,470.59}, {33.6,471.36}, {25.6,470.68}, {21.6,469.67}, {18.6,468.57}, {14.6,466.62}, {11.6,464.61}, {8.6,461.89},
    {6.35,459.4}, {4.27,456.4}, {2.25,452.4}, {1.21,449.4}, {0.29,445.4}, {-0.07,439.4}, {-0.08,300.4}, {-0.04,299.4},
    {0.6,298.19}, {2.6,297.96}, {22.6,297.96}, {23.6,298.12}, {24.35,299.4}, {24.45,438.4}, {25.19,442.4}, {26.16,444.4},
    {26.98,445.4}, {29.6,447.59}, {33.6,448.4}, {37.6,447.84}, {40,446.4}, {41.71,444.4}, {42.63,442.4}, {42.99,441.4},
    {43.21,439.4}, {43.29,267.4}, {42.6,266.84}, {39.6,268.65}, {34.6,270.57}, {28.6,271.57}, {26.6,271.65}, {23.6,271.47},
    {18.6,270.69}, {15.6,269.71}, {11.6,267.66}, {8.88,265.4}, {6.12,262.4}, {4.17,259.4}, {3.17,257.4}, {2.31,255.4},
    {1.15,251.4}, {0.21,246.4}, {-0.03,241.4}, {-0.37,33.4}, {0.17,25.4}, {1.44,20.4}, {2.21,18.4}, {4.3,14.4},
    {7.32,10.4}, {10.6,7.27}, {13.6,5.07}, {19.6,2.14}, {22.6,1.15}, {26.6,0.3}, {31.6,-0.15}, {39.6,0.04},
    {44.6,1.02}, {47.6,1.98}, {52.6,4.19}, {55.6,6.06}, {57.21,7.4}, {59.6,9.62}, {62.87,13.4}, {65.6,18.42},
    {66.75,21.4}, {67.91,26.4}, {68.19,31.4}, {68.2,438.4}, {68.05,443.4}, {66.88,449.4}, {65.82,452.4}, {63.77,456.4},
    {59.93,461.4}, {57.6,463.61}, {54.6,465.82}, {51.6,467.5}, {46.6,469.51}
};
static const COCPt kG9_1[] = {
    {36.27,248.4}, {38.6,247.51}, {39.6,246.82}, {41.76,244.4}, {43.02,241.4}, {43.26,238.4}, {43.3,33.4}, {42.92,29.4},
    {42.07,27.4}, {40.68,25.4}, {39.48,24.4}, {37.6,23.32}, {36.6,22.98}, {33.6,22.79}, {30.6,23.12}, {28.6,24.11},
    {27.17,25.4}, {26.33,26.4}, {25.29,28.4}, {24.41,33.4}, {24.4,237.4}, {24.53,239.4}, {25.4,243.4}, {26.54,245.4},
    {27.6,246.65}, {29.6,247.91}, {31.6,248.62}, {34.6,248.76}
};

typedef struct { const COCPt *v; int n; } COCRing;
static const COCRing kR0[] = { {kG0_0,47}, {kG0_1,27} };
static const COCRing kR1[] = { {kG1_0,36} };
static const COCRing kR2[] = { {kG2_0,85} };
static const COCRing kR3[] = { {kG3_0,123} };
static const COCRing kR4[] = { {kG4_0,51}, {kG4_1,8} };
static const COCRing kR5[] = { {kG5_0,100} };
static const COCRing kR6[] = { {kG6_0,88}, {kG6_1,26} };
static const COCRing kR7[] = { {kG7_0,51} };
static const COCRing kR8[] = { {kG8_0,82}, {kG8_1,25}, {kG8_2,27} };
static const COCRing kR9[] = { {kG9_0,85}, {kG9_1,28} };

static const COCRing *COCRingsFor(unichar ch, int *count) {
    switch (ch) {
        case '0': *count = 2; return kR0;
        case '1': *count = 1; return kR1;
        case '2': *count = 1; return kR2;
        case '3': *count = 1; return kR3;
        case '4': *count = 2; return kR4;
        case '5': *count = 1; return kR5;
        case '6': *count = 2; return kR6;
        case '7': *count = 1; return kR7;
        case '8': *count = 3; return kR8;
        case '9': *count = 2; return kR9;
        default: *count = 0; return NULL;
    }
}


// ===== COC-CORE-BEGIN =====
// Чистая геометрия (без UIKit): раскладка «развёрнуто» / «свёрнуто» и траектория между ними.
// Этот блок компилируется и проверяется отдельно, вне телефона.

#define COC_BW 68.0
#define COC_CH 472.0
#define COC_PITCH 91.0
#define COC_LINEGAP 14.0
#define COC_PADX 10.0
#define COC_PADY 1.0

// Растяжение цифр по горизонтали относительно нативных пропорций листа (1.0 = как на листе):
//   FULL    — «во всю ширину» и вертикальные цифры слева
//   COMPACT — компактный вариант с виджетами сбоку, чуть шире
//   SMALL   — малые часы при уведомлениях (шире и приземистее, как на референсе 1605)
#define COC_STRETCH_FULL 1.43
#define COC_STRETCH_COMPACT 1.60
#define COC_STRETCH_SMALL 2.10

#define COC_MAXW 8

static inline CGFloat COCBlockW(NSUInteger m) { return (m - 1) * COC_PITCH + COC_BW; }
static inline CGFloat COCBlockH(NSUInteger n) { return n * COC_CH + (n - 1) * COC_LINEGAP; }

// Отношение высота/ширина блока из m цифр в n строк при растяжении stretch.
static inline CGFloat COCAspect(NSUInteger m, NSUInteger n, CGFloat stretch) {
    return COCBlockH(n) / (COCBlockW(m) * stretch);
}

static inline CGFloat COCClamp01(CGFloat x) { return x < 0 ? 0 : (x > 1 ? 1 : x); }
static inline CGFloat COCWin(CGFloat p, CGFloat a, CGFloat b) { return COCClamp01((p - a) / (b - a)); }
static inline CGFloat COCSmooth(CGFloat t) { return t * t * (3 - 2 * t); }
static inline CGFloat COCMix(CGFloat a, CGFloat b, CGFloat t) { return a + (b - a) * t; }

// Положение — по осям отдельно (так получается дуга), размер — по среднему прогрессу.
static CGRect COCMixRect(CGRect a, CGRect b, CGFloat tx, CGFloat ty) {
    CGFloat ts = (tx + ty) * 0.5;
    return CGRectMake(COCMix(a.origin.x, b.origin.x, tx), COCMix(a.origin.y, b.origin.y, ty),
                      COCMix(a.size.width, b.size.width, ts), COCMix(a.size.height, b.size.height, ts));
}

// Рамка вида из двух цифр = блок плюс поля под выступающие части глифов («4», «2», «7»).
static CGRect COCPairFrame(CGRect b) {
    CGFloat px = COC_PADX * b.size.width / COCBlockW(2);
    CGFloat py = COC_PADY * b.size.height / COC_CH;
    return CGRectInset(b, -px, -py);
}

// Блок из 4 цифр в одну строку -> блок часов (цифры 0–1) и блок минут (цифры 2–3).
static void COCSplitBlock4(CGRect b, CGRect *h, CGRect *m) {
    CGFloat f = b.size.width / COCBlockW(4);
    CGFloat w2 = COCBlockW(2) * f;
    *h = CGRectMake(b.origin.x, b.origin.y, w2, b.size.height);
    *m = CGRectMake(b.origin.x + 2 * COC_PITCH * f, b.origin.y, w2, b.size.height);
}

static CGRect COCRectAroundCenter(CGSize s, CGPoint c) {
    return CGRectMake(c.x - s.width / 2, c.y - s.height / 2, s.width, s.height);
}

static CGPoint COCCenter(CGRect r) {
    return CGPointMake(r.origin.x + r.size.width / 2, r.origin.y + r.size.height / 2);
}

typedef struct {
    CGRect R;            // область контента (после отступов и сдвига)
    CGFloat sx, sy;      // растяжение развёрнутых цифр («размер» × «ширина/высота»)
    CGFloat k;           // общий масштаб («размер»)
    CGFloat ws;          // масштаб виджетов
    CGFloat smallK;      // масштаб малых часов
    int style;           // 1, 2 или 3
    int n;               // число виджетов
    CGSize date;         // развёрнутая дата (1 и 2: три строки, 3: одна строка)
    CGSize weather;      // погода справа в строке даты (вариант 3)
    CGSize dateS;        // малая дата справа (три строки)
} COCLayoutIn;

typedef struct {
    CGRect hours, mins;          // рамки видов цифр (с полями)
    CGRect date, weather, dateS; // подписи
    CGRect card[COC_MAXW];       // квадраты виджетов
    CGFloat sq;                  // сторона квадрата
    CGFloat bottom;              // нижняя граница всего блока
} COCLayoutOut;

static void COCLayoutExpanded(const COCLayoutIn *in, COCLayoutOut *o) {
    CGRect R = in->R;
    CGFloat u = R.size.width;
    CGRect dr;
    memset(o, 0, sizeof(*o));

    if (in->style == 3) {
        // Строка «дата — погода», 0851 во всю ширину, виджеты под цифрами
        CGFloat rowH = MAX(in->date.height, in->weather.height);
        o->date = CGRectMake(R.origin.x, R.origin.y, in->date.width, in->date.height);
        o->weather = CGRectMake(CGRectGetMaxX(R) - in->weather.width, R.origin.y,
                                in->weather.width, in->weather.height);
        dr = CGRectMake(R.origin.x, R.origin.y + rowH + 14,
                        u * in->sx, u * COCAspect(4, 1, COC_STRETCH_FULL) * in->sy);
        COCSplitBlock4(dr, &o->hours, &o->mins);
    } else if (in->style == 2) {
        // Компактное 0851 (~68% ширины), дата под цифрами, виджеты колонкой справа
        CGFloat bw = u * 0.68;
        dr = CGRectMake(R.origin.x, R.origin.y,
                        bw * in->sx, bw * COCAspect(4, 1, COC_STRETCH_COMPACT) * in->sy);
        COCSplitBlock4(dr, &o->hours, &o->mins);
    } else {
        // Вертикальные цифры слева (08 над 51), виджеты колонкой справа
        CGFloat bw = u * 0.36;
        CGFloat bh = bw * COCAspect(2, 2, COC_STRETCH_FULL);
        dr = CGRectMake(R.origin.x, R.origin.y, bw * in->sx, bh * in->sy);
        CGFloat lineH = dr.size.height * COC_CH / COCBlockH(2);
        CGFloat gap = dr.size.height * COC_LINEGAP / COCBlockH(2);
        o->hours = CGRectMake(dr.origin.x, dr.origin.y, dr.size.width, lineH);
        o->mins = CGRectMake(dr.origin.x, dr.origin.y + lineH + gap, dr.size.width, lineH);
    }
    if (in->style != 3) {
        o->date = CGRectMake(R.origin.x, CGRectGetMaxY(dr) + 12, in->date.width, in->date.height);
        o->weather = CGRectMake(CGRectGetMaxX(R), R.origin.y, 0, 0);
    }
    o->hours = COCPairFrame(o->hours);
    o->mins = COCPairFrame(o->mins);

    CGFloat sq = 0.19 * u * in->ws;
    CGFloat colGap = MAX(8, sq * 0.18);
    o->sq = sq;
    CGFloat bottom = MAX(CGRectGetMaxY(dr), CGRectGetMaxY(o->date));
    for (int i = 0; i < in->n && i < COC_MAXW; i++) {
        CGFloat x, y;
        if (in->style == 3) {
            // Ряд под цифрами: 1 — слева, 2 — по краям, 3+ — равномерно
            y = CGRectGetMaxY(dr) + u * 0.07;
            x = (in->n == 1) ? R.origin.x : R.origin.x + i * (u - sq) / (in->n - 1);
        } else {
            // Колонка квадратов у правого края
            x = CGRectGetMaxX(R) - sq;
            y = R.origin.y + i * (sq + colGap);
        }
        o->card[i] = CGRectMake(x, y, sq, sq);
        bottom = MAX(bottom, y + sq);
    }
    o->bottom = bottom;
}

static void COCLayoutCollapsed(const COCLayoutIn *in, COCLayoutOut *o, CGFloat sqExpanded) {
    CGRect R = in->R;
    CGFloat u = R.size.width;
    memset(o, 0, sizeof(*o));

    // Малые часы слева сверху, дата справа, виджеты рядом снизу — одинаково для всех вариантов
    CGFloat cw = u * 0.34 * in->k * in->smallK;
    CGRect dr = CGRectMake(R.origin.x, R.origin.y, cw, cw * COCAspect(4, 1, COC_STRETCH_SMALL));
    COCSplitBlock4(dr, &o->hours, &o->mins);
    o->hours = COCPairFrame(o->hours);
    o->mins = COCPairFrame(o->mins);

    o->dateS = CGRectMake(CGRectGetMaxX(R) - in->dateS.width, R.origin.y - 2,
                          in->dateS.width, in->dateS.height);

    CGFloat sq = sqExpanded;
    int n = in->n < COC_MAXW ? in->n : COC_MAXW;
    if (n > 0 && n * sq + (n - 1) * 8 > u) sq = (u - (n - 1) * 8) / n;
    o->sq = sq;
    CGFloat gapH = (n > 1) ? MIN(16, (u - n * sq) / (n - 1)) : 0;
    CGFloat y = CGRectGetMaxY(dr) + 20;
    CGFloat bottom = MAX(CGRectGetMaxY(dr), CGRectGetMaxY(o->dateS));
    for (int i = 0; i < n; i++) {
        o->card[i] = CGRectMake(R.origin.x + i * (sq + gapH), y, sq, sq);
        bottom = MAX(bottom, y + sq);
    }
    o->bottom = bottom;
}

// Обе раскладки сразу; подписи «стыкуются» центрами, чтобы переход выглядел как перетекание.
static void COCComputeLayout(const COCLayoutIn *in, COCLayoutOut *E, COCLayoutOut *C) {
    COCLayoutExpanded(in, E);
    COCLayoutCollapsed(in, C, E->sq);
    E->dateS = COCRectAroundCenter(in->dateS.width > 0 || in->dateS.height > 0
                                       ? in->dateS : in->date,
                                   COCCenter(E->date));
    C->date = COCRectAroundCenter(in->date, COCCenter(C->dateS));
    C->weather = COCRectAroundCenter(in->weather, COCCenter(C->dateS));
}

// Хореография: у каждого варианта свои окна прогресса. Для каждого элемента:
//   [w0, w1] — окно на общей шкале 0..1, внутри него отдельные окна для осей x и y.
// Так траектории получаются «Г-образными» и элементы не наезжают друг на друга.
typedef struct {
    CGFloat h0, h1, hx0, hx1, hy0, hy1;   // часы
    CGFloat m0, m1, mx0, mx1, my0, my1;   // минуты
    CGFloat c0, cs, cx0, cx1, cy0, cy1;   // карточки: окно [c0 + i*cs, 1]
    CGFloat dOut;                         // старая дата исчезает к dOut
    CGFloat dIn0;                         // малая дата проявляется с dIn0
} COCChoreo;

static const COCChoreo kChoreo[3] = {
    /* 1: вертикальные — часы сжимаются первыми, минуты уезжают вправо, а потом вверх на место */
    { 0.00, 0.60, 0.0, 1.0, 0.0, 1.0,
      0.18, 0.82, 0.0, 0.5, 0.4, 1.0,
      0.40, 0.05, 0.0, 1.0, 0.0, 1.0,
      0.30, 0.70 },
    /* 2: компактные — цифры уходят почти вместе, виджеты спускаются и подъезжают рядом */
    { 0.00, 0.62, 0.0, 1.0, 0.0, 1.0,
      0.04, 0.66, 0.0, 1.0, 0.0, 1.0,
      0.40, 0.05, 0.0, 1.0, 0.0, 1.0,
      0.38, 0.70 },
    /* 3: во всю ширину — цифры сжимаются вверх, строка даты перетекает вправо, ряд виджетов поднимается */
    { 0.00, 0.62, 0.0, 1.0, 0.0, 1.0,
      0.03, 0.66, 0.0, 1.0, 0.0, 1.0,
      0.25, 0.05, 0.5, 1.0, 0.0, 0.55,
      0.35, 0.55 },
};

typedef struct {
    CGRect hours, mins, date, weather, dateS;
    CGFloat dateA, weatherA, dateSA;
    CGRect card[COC_MAXW];
} COCFrame;

// Прогресс элемента по осям: окно [w0, w1] общей шкалы, внутри — окна оси x и оси y.
static void COCAxes(CGFloat p, CGFloat w0, CGFloat w1, CGFloat x0, CGFloat x1,
                    CGFloat y0, CGFloat y1, CGFloat *tx, CGFloat *ty) {
    CGFloat t = COCWin(p, w0, w1);
    *tx = COCSmooth(COCWin(t, x0, x1));
    *ty = COCSmooth(COCWin(t, y0, y1));
}

static void COCInterpolate(const COCLayoutOut *E, const COCLayoutOut *C, int style, int n,
                           CGFloat p, COCFrame *f) {
    const COCChoreo *c = &kChoreo[(style < 1 || style > 3) ? 0 : style - 1];
    CGFloat tx, ty;
    p = COCClamp01(p);
    memset(f, 0, sizeof(*f));

    COCAxes(p, c->h0, c->h1, c->hx0, c->hx1, c->hy0, c->hy1, &tx, &ty);
    f->hours = COCMixRect(E->hours, C->hours, tx, ty);
    COCAxes(p, c->m0, c->m1, c->mx0, c->mx1, c->my0, c->my1, &tx, &ty);
    f->mins = COCMixRect(E->mins, C->mins, tx, ty);

    CGFloat td = COCSmooth(COCWin(p, 0, 0.90));
    f->date = COCMixRect(E->date, C->date, td, td);
    f->weather = COCMixRect(E->weather, C->weather, td, td);
    f->dateA = 1 - COCWin(p, 0, c->dOut);
    f->weatherA = 1 - COCWin(p, 0, c->dOut * 0.85);

    CGFloat ts = COCSmooth(COCWin(p, 0.10, 1.0));
    f->dateS = COCMixRect(E->dateS, C->dateS, ts, ts);
    f->dateSA = COCSmooth(COCWin(p, c->dIn0, 1.0));

    for (int i = 0; i < n && i < COC_MAXW; i++) {
        COCAxes(p, c->c0 + i * c->cs, 1.0, c->cx0, c->cx1, c->cy0, c->cy1, &tx, &ty);
        f->card[i] = COCMixRect(E->card[i], C->card[i], tx, ty);
    }
}

// Цель сжатия по геометрии списка: top — верх самой высокой видимой ячейки уведомления
// в координатах страницы, H — высота страницы, dist — путь, на котором часы сжимаются полностью.
// Нет ячеек → top = H или больше → 0; ячейка поднялась на dist и выше → 1.
static inline CGFloat COCCollapseTarget(CGFloat top, CGFloat H, CGFloat dist) {
    if (dist < 1) dist = 1;
    return COCClamp01((H - top) / dist);
}
// ===== COC-CORE-END =====


static void COCAddRing(CGMutablePathRef p, const COCPt *v, int n) {
    if (n < 3) return;
    CGPathMoveToPoint(p, NULL, v[0].x, v[0].y);
    for (int i = 1; i < n; i++) CGPathAddLineToPoint(p, NULL, v[i].x, v[i].y);
    CGPathCloseSubpath(p);
}

static CGPathRef COCGlyphPath(unichar ch) {
    static CGPathRef cache[10];
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        for (int d = 0; d < 10; d++) {
            int cnt = 0;
            const COCRing *rings = COCRingsFor((unichar)('0' + d), &cnt);
            CGMutablePathRef p = CGPathCreateMutable();
            for (int i = 0; i < cnt; i++) COCAddRing(p, rings[i].v, rings[i].n);
            cache[d] = p;
        }
    });
    return (ch >= '0' && ch <= '9') ? cache[ch - '0'] : NULL;
}


#pragma mark - Вид с двумя цифрами (CAShapeLayer: путь перестраивается только при смене размера/текста)

@interface COCDigitsView : UIView
@property (nonatomic, copy) NSString *text;               // две цифры, например "08"
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat outlineAlpha;       // 0 — без контура
@end

@implementation COCDigitsView {
    CAShapeLayer *_shape;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        _color = [UIColor whiteColor];
        _outlineAlpha = 0.38;
        _shape = [CAShapeLayer layer];
        _shape.fillRule = kCAFillRuleEvenOdd;
        _shape.lineJoin = kCALineJoinRound;
        _shape.contentsScale = UIScreen.mainScreen.scale;
        [self.layer addSublayer:_shape];
        [self applyStyle];
    }
    return self;
}

- (void)applyStyle {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _shape.fillColor = _color.CGColor;
    _shape.strokeColor = _outlineAlpha > 0.001 ? [UIColor colorWithWhite:1 alpha:_outlineAlpha].CGColor : NULL;
    [CATransaction commit];
}

- (void)setText:(NSString *)text {
    if ([_text isEqualToString:text]) return;
    _text = [text copy];
    [self setNeedsLayout];
}
- (void)setColor:(UIColor *)c { _color = c; [self applyStyle]; }
- (void)setOutlineAlpha:(CGFloat)a { _outlineAlpha = a; [self applyStyle]; }

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect B = self.bounds;
    NSUInteger m = _text.length;

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    _shape.frame = B;
    if (m == 0 || B.size.width < 1 || B.size.height < 1) {
        _shape.path = NULL;
    } else {
        // Нативные единицы -> точки вида (вместе с полями под выступающие части глифов)
        CGFloat sx = B.size.width / (COCBlockW(m) + 2 * COC_PADX);
        CGFloat sy = B.size.height / (COC_CH + 2 * COC_PADY);
        CGMutablePathRef mp = CGPathCreateMutable();
        for (NSUInteger j = 0; j < m; j++) {
            CGPathRef gp = COCGlyphPath([_text characterAtIndex:j]);
            if (!gp) continue;
            CGAffineTransform t = CGAffineTransformMake(sx, 0, 0, sy, (COC_PADX + j * COC_PITCH) * sx, COC_PADY * sy);
            CGPathAddPath(mp, &t, gp);
        }
        _shape.path = mp;
        _shape.lineWidth = MAX(0.8, COC_CH * sy * 0.0030);
        CGPathRelease(mp);
    }
    [CATransaction commit];
}

@end

#pragma mark - Карточка виджета (квадрат, прозрачная заливка без размытия)

@interface COCWidgetCard : UIView
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, assign) CGFloat fillAlpha;
- (void)setSymbol:(NSString *)symbol value:(NSString *)value;
@end

@implementation COCWidgetCard {
    CGFloat _lastW;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.clipsToBounds = YES;
        self.userInteractionEnabled = NO;

        _iconView = [[UIImageView alloc] init];
        _iconView.tintColor = [UIColor whiteColor];
        _iconView.contentMode = UIViewContentModeTopLeft;
        [self addSubview:_iconView];

        _valueLabel = [[UILabel alloc] init];
        _valueLabel.textColor = [UIColor whiteColor];
        _valueLabel.adjustsFontSizeToFitWidth = YES;
        _valueLabel.minimumScaleFactor = 0.5;
        [self addSubview:_valueLabel];

        self.fillAlpha = 0.1;
    }
    return self;
}

// Просто полупрозрачная белая заливка — обои видны сквозь карточку, как на референсе
- (void)setFillAlpha:(CGFloat)fillAlpha {
    _fillAlpha = fillAlpha;
    self.backgroundColor = [UIColor colorWithWhite:1 alpha:fillAlpha];
}

- (void)setSymbol:(NSString *)symbol value:(NSString *)value {
    if ([_symbol isEqualToString:symbol] && [_valueLabel.text isEqualToString:value]) return;
    _symbol = [symbol copy];
    _valueLabel.text = value;
    _iconView.image = nil;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width, h = self.bounds.size.height;
    CGFloat pad = w * 0.17;

    // Иконка и шрифт зависят только от ширины — не пересоздаём их, пока размер не изменился
    if (!_iconView.image || fabs(w - _lastW) > 0.5) {
        _lastW = w;
        UIImageSymbolConfiguration *cfg =
            [UIImageSymbolConfiguration configurationWithPointSize:w * 0.30 weight:UIImageSymbolWeightMedium];
        _iconView.image = _symbol ? [UIImage systemImageNamed:_symbol withConfiguration:cfg] : nil;
        _valueLabel.font = COCRounded(w * 0.24, UIFontWeightSemibold);
    }
    _iconView.frame = CGRectMake(pad, pad, w - pad * 2, w * 0.36);
    _valueLabel.frame = CGRectMake(pad, h - pad - w * 0.30, w - pad * 2, w * 0.30);
}

@end


#pragma mark - Погода (open-meteo, без ключа)

static BOOL COCWValid = NO;
static double COCWTemp = 0;
static int COCWCode = 0;
static NSDate *COCWFetched = nil;
static BOOL COCWBusy = NO;
static NSString *COCWGeoCity = nil;
static double COCWLat = 0, COCWLon = 0;

static NSString *COCWeatherSymbol(int c) {
    if (c == 0) return @"sun.max.fill";
    if (c == 1 || c == 2) return @"cloud.sun.fill";
    if (c == 3) return @"cloud.fill";
    if (c == 45 || c == 48) return @"cloud.fog.fill";
    if (c >= 51 && c <= 57) return @"cloud.drizzle.fill";
    if (c >= 61 && c <= 67) return @"cloud.rain.fill";
    if ((c >= 71 && c <= 77) || c == 85 || c == 86) return @"cloud.snow.fill";
    if (c >= 80 && c <= 82) return @"cloud.heavyrain.fill";
    if (c >= 95) return @"cloud.bolt.rain.fill";
    return @"cloud.fill";
}

static void COCWeatherRefresh(NSString *city) {
    if (city.length == 0 || COCWBusy) return;
    if (COCWFetched && -[COCWFetched timeIntervalSinceNow] < 1200 &&
        [city isEqualToString:COCWGeoCity]) return;
    COCWBusy = YES;

    void (^finish)(BOOL, double, int, double, double) =
        ^(BOOL ok, double t, int code, double lat, double lon) {
            dispatch_async(dispatch_get_main_queue(), ^{
                COCWBusy = NO;
                if (ok) {
                    COCWValid = YES; COCWTemp = t; COCWCode = code;
                    COCWLat = lat; COCWLon = lon; COCWGeoCity = city;
                    COCWFetched = [NSDate date];
                } else {
                    COCWFetched = [NSDate dateWithTimeIntervalSinceNow:-1000]; // повтор через ~3 мин
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:COCWeatherUpdated object:nil];
            });
        };

    void (^forecast)(double, double) = ^(double lat, double lon) {
        NSString *u = [NSString stringWithFormat:
            @"https://api.open-meteo.com/v1/forecast?latitude=%.4f&longitude=%.4f"
            @"&current=temperature_2m,weather_code&timezone=auto", lat, lon];
        NSURLSessionDataTask *t = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:u]
            completionHandler:^(NSData *data, NSURLResponse *resp, NSError *err) {
                NSDictionary *j = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
                NSDictionary *cur = [j isKindOfClass:[NSDictionary class]] ? j[@"current"] : nil;
                if ([cur isKindOfClass:[NSDictionary class]] && cur[@"temperature_2m"]) {
                    finish(YES, [cur[@"temperature_2m"] doubleValue], [cur[@"weather_code"] intValue], lat, lon);
                } else {
                    finish(NO, 0, 0, 0, 0);
                }
            }];
        [t resume];
    };

    if ([city isEqualToString:COCWGeoCity] && (COCWLat != 0 || COCWLon != 0)) {
        forecast(COCWLat, COCWLon);
        return;
    }

    NSString *enc = [city stringByAddingPercentEncodingWithAllowedCharacters:
                        [NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *g = [NSString stringWithFormat:
        @"https://geocoding-api.open-meteo.com/v1/search?name=%@&count=1", enc];
    NSURLSessionDataTask *gt = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:g]
        completionHandler:^(NSData *data, NSURLResponse *resp, NSError *err) {
            NSDictionary *j = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
            NSArray *res = [j isKindOfClass:[NSDictionary class]] ? j[@"results"] : nil;
            NSDictionary *first = ([res isKindOfClass:[NSArray class]] && res.count) ? res[0] : nil;
            if ([first isKindOfClass:[NSDictionary class]] && first[@"latitude"]) {
                forecast([first[@"latitude"] doubleValue], [first[@"longitude"] doubleValue]);
            } else {
                finish(NO, 0, 0, 0, 0);
            }
        }];
    [gt resume];
}

#pragma mark - Ближайший будильник (MobileTimer, с защитой от отсутствия API)

static NSDate *COCNextAlarmDate(void) {
    static id mgr = nil;
    static dispatch_once_t once;
    static NSDate *cached = nil, *checked = nil;
    dispatch_once(&once, ^{
        dlopen("/System/Library/PrivateFrameworks/MobileTimer.framework/MobileTimer", RTLD_LAZY);
        Class c = NSClassFromString(@"MTAlarmManager");
        if (c) mgr = [[c alloc] init];
    });
    if (!mgr) return nil;
    if (checked && -[checked timeIntervalSinceNow] < 30) return cached;
    checked = [NSDate date];
    cached = nil;
    @try {
        SEL s = NSSelectorFromString(@"nextAlarmSync");
        if ([mgr respondsToSelector:s]) {
            id alarm = ((id (*)(id, SEL))objc_msgSend)(mgr, s);
            if (alarm) {
                if ([alarm respondsToSelector:NSSelectorFromString(@"nextFireDate")]) {
                    cached = [alarm valueForKey:@"nextFireDate"];
                }
                if (!cached && [alarm respondsToSelector:NSSelectorFromString(@"hour")] &&
                    [alarm respondsToSelector:NSSelectorFromString(@"minute")]) {
                    NSInteger hh = [[alarm valueForKey:@"hour"] integerValue];
                    NSInteger mm = [[alarm valueForKey:@"minute"] integerValue];
                    cached = [[NSCalendar currentCalendar] nextDateAfterDate:[NSDate date]
                                                               matchingHour:hh minute:mm second:0
                                                                    options:NSCalendarMatchNextTime];
                }
            }
        }
    } @catch (NSException *e) {
        cached = nil;
    }
    return cached;
}

#pragma mark - Часы

typedef NS_ENUM(NSInteger, COCWidgetType) {
    COCWidgetAlarm = 0,
    COCWidgetWeather,
    COCWidgetBattery,
    COCWidgetDate,
    COCWidgetText,
};

static UIColor *COCRGB(CGFloat r, CGFloat g, CGFloat b) {
    return [UIColor colorWithRed:r green:g blue:b alpha:1];
}

static UIColor *COCMixWhite(UIColor *c, CGFloat k) {
    CGFloat r = 1, g = 1, b = 1, a = 1;
    [c getRed:&r green:&g blue:&b alpha:&a];
    return COCRGB(r + (1 - r) * k, g + (1 - g) * k, b + (1 - b) * k);
}

// Средний цвет обоев экрана блокировки (приватный API SpringBoard; может быть недоступен)
static UIColor *COCWallpaperAverage(void) {
    static UIColor *cached = nil;
    static NSDate *when = nil;
    if (when && -[when timeIntervalSinceNow] < 20) return cached;
    UIColor *c = nil;
    @try {
        Class k = NSClassFromString(@"SBWallpaperController");
        SEL sh = NSSelectorFromString(@"sharedInstance");
        if (k && [k respondsToSelector:sh]) {
            id inst = ((id (*)(id, SEL))objc_msgSend)(k, sh);
            SEL av = NSSelectorFromString(@"averageColorForVariant:");
            if (inst && [inst respondsToSelector:av]) {
                id r = ((id (*)(id, SEL, long long))objc_msgSend)(inst, av, 0);   // 0 = экран блокировки
                if ([r isKindOfClass:[UIColor class]]) c = r;
            }
        }
    } @catch (NSException *e) {
        c = nil;
    }
    cached = c;
    when = [NSDate date];
    return c;
}

// Плоские цвета без градиентов: hour — левая часть (чуть светлее), minute — правая.
// Индексы: 0 — как на референсе 1, 1 — светлый как на референсе 2, 2..7 — пастель, 8 — под обои.
static void COCClockColors(NSInteger idx, BOOL duo, UIColor **hour, UIColor **minute) {
    UIColor *h = nil, *m = nil;
    switch (idx) {
        case 0:
            h = COCRGB(0.76, 0.65, 0.66);
            m = COCRGB(0.67, 0.58, 0.63);
            break;
        case 1:
            h = COCRGB(0.98, 0.97, 0.96);
            m = COCRGB(0.90, 0.89, 0.88);
            break;
        case 2: m = COCRGB(0.82, 0.79, 0.97); break;   // лавандовый
        case 3: m = COCRGB(0.70, 0.80, 0.97); break;   // голубой
        case 4: m = COCRGB(0.66, 0.86, 0.96); break;   // бирюзовый
        case 5: m = COCRGB(0.84, 0.70, 0.97); break;   // сиреневый
        case 6: m = COCRGB(0.97, 0.70, 0.68); break;   // розовый
        case 7: m = COCRGB(0.97, 0.82, 0.68); break;   // персиковый
        case 8: {
            UIColor *w = COCWallpaperAverage();
            CGFloat hu = 0, sa = 0, br = 0, al = 1;
            if (w && [w getHue:&hu saturation:&sa brightness:&br alpha:&al]) {
                BOOL lightWall = br > 0.78;
                CGFloat sat = MIN(sa * 0.9, 0.34);
                m = [UIColor colorWithHue:hu saturation:sat brightness:(lightWall ? 0.28 : 0.86) alpha:1];
                h = [UIColor colorWithHue:hu saturation:MAX(sat - 0.08, 0)
                               brightness:(lightWall ? 0.20 : 0.96) alpha:1];
            } else {
                h = COCRGB(0.76, 0.65, 0.66);
                m = COCRGB(0.67, 0.58, 0.63);
            }
            break;
        }
        default:
            h = COCRGB(0.76, 0.65, 0.66);
            m = COCRGB(0.67, 0.58, 0.63);
            break;
    }
    if (!h) h = COCMixWhite(m, 0.16);
    if (!duo) h = m;
    *hour = h;
    *minute = m;
}

#pragma mark - Слежение за уведомлениями (геометрия ячеек на экране)

static __weak UIView *COCListHint;   // вид списка уведомлений (подсказка из Tweak.xm)

static BOOL COCIsNotifCell(UIView *v) {
    static Class cellCls;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ cellCls = NSClassFromString(@"NCNotificationListCell"); });
    if (cellCls && [v isKindOfClass:cellCls]) return YES;
    const char *n = object_getClassName(v);
    return n && strstr(n, "NotificationListCell") != NULL;
}

// Где ячейка на самом деле находится сейчас (по presentationLayer — виден и ход анимаций UIKit,
// и палец, ведущий список). Координаты — в системе root.
static BOOL COCPresentedRect(UIView *v, CALayer *root, CGRect *out, CGFloat *alpha) {
    CALayer *l = v.layer;
    CGRect b0 = (l.presentationLayer ?: l).bounds;
    CGPoint pts[4] = {
        CGPointMake(CGRectGetMinX(b0), CGRectGetMinY(b0)), CGPointMake(CGRectGetMaxX(b0), CGRectGetMinY(b0)),
        CGPointMake(CGRectGetMinX(b0), CGRectGetMaxY(b0)), CGPointMake(CGRectGetMaxX(b0), CGRectGetMaxY(b0)) };
    CGFloat a = 1;
    int guard = 0;
    while (l && l != root && guard++ < 48) {
        CALayer *pl = l.presentationLayer ?: l;
        if (pl.hidden) return NO;
        a *= pl.opacity;
        CGRect b = pl.bounds;
        CGPoint pos = pl.position, an = pl.anchorPoint;
        CGAffineTransform t = CATransform3DGetAffineTransform(pl.transform);
        CGFloat ox = b.origin.x + an.x * b.size.width, oy = b.origin.y + an.y * b.size.height;
        for (int i = 0; i < 4; i++) {
            CGPoint q = CGPointApplyAffineTransform(CGPointMake(pts[i].x - ox, pts[i].y - oy), t);
            pts[i] = CGPointMake(pos.x + q.x, pos.y + q.y);
        }
        l = l.superlayer;
    }
    CGFloat x0 = pts[0].x, x1 = pts[0].x, y0 = pts[0].y, y1 = pts[0].y;
    for (int i = 1; i < 4; i++) {
        x0 = MIN(x0, pts[i].x); x1 = MAX(x1, pts[i].x);
        y0 = MIN(y0, pts[i].y); y1 = MAX(y1, pts[i].y);
    }
    if (!isfinite(x0 + x1 + y0 + y1)) return NO;
    *out = CGRectMake(x0, y0, x1 - x0, y1 - y0);
    *alpha = a;
    return YES;
}

static void COCCollectCells(UIView *v, int depth, int *budget, UIView *skip, NSMutableArray<UIView *> *out) {
    if (depth > 14) return;
    for (UIView *s in v.subviews) {
        if (--(*budget) <= 0) return;
        if (s == skip || s.hidden) continue;
        if (COCIsNotifCell(s)) { [out addObject:s]; continue; }
        COCCollectCells(s, depth + 1, budget, skip, out);
    }
}

#pragma mark - Таймер анимации (через слабую ссылку, чтобы не удерживать вид)

@interface COCClockView (Driver)
- (void)displayTick:(CADisplayLink *)link;
@end

@interface COCLinkProxy : NSObject
- (instancetype)initWithTarget:(COCClockView *)t;
- (void)fire:(CADisplayLink *)l;
@end

@implementation COCLinkProxy {
    __weak COCClockView *_t;
}
- (instancetype)initWithTarget:(COCClockView *)t {
    if ((self = [super init])) _t = t;
    return self;
}
- (void)fire:(CADisplayLink *)l {
    COCClockView *t = _t;
    if (t) [t displayTick:l]; else [l invalidate];
}
@end


@interface COCClockView (Gesture) <UIGestureRecognizerDelegate>
@end

#pragma mark - Редактор размера и положения (долгое нажатие на экране блокировки)

@interface COCClockView (Editor)
- (CGRect)editorFrame;              // рамка цифр в развёрнутом виде
- (CGRect)editorDragFrame;          // цифры + дата: за что можно тянуть
- (void)editorSnapshot;             // запомнить значения перед жестом
- (void)editorMoveBy:(CGPoint)d;
- (void)editorResizeCorner:(CGPoint)corner lockRatio:(BOOL)lock;
- (void)editorReset;
- (void)endEditingSave:(BOOL)save;
@end

@interface COCEditorView : UIView <UIGestureRecognizerDelegate>
- (instancetype)initWithClock:(COCClockView *)clock;
- (void)refresh;
@end

@implementation COCEditorView {
    __weak COCClockView *_clock;
    UIView *_frameV;
    UIView *_gripV;
    UIButton *_done, *_cancel, *_reset, *_ratio;
    UILabel *_title, *_hint;
    UIPanGestureRecognizer *_pan;
    int _mode;                  // 0 — нет, 1 — перенос, 2 — размер
    CGPoint _startCorner;
    BOOL _keepRatio;
}

static UIButton *COCPill(NSString *title, UIColor *bg, UIColor *fg) {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:fg forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    b.backgroundColor = bg;
    b.contentEdgeInsets = UIEdgeInsetsMake(8, 16, 8, 16);
    b.layer.cornerRadius = 18;
    [b sizeToFit];
    CGRect f = b.frame;
    f.size.height = 36;
    b.frame = f;
    return b;
}

- (instancetype)initWithClock:(COCClockView *)clock {
    if ((self = [super initWithFrame:CGRectZero])) {
        _clock = clock;
        _keepRatio = YES;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.30];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        _frameV = [[UIView alloc] init];
        _frameV.userInteractionEnabled = NO;
        _frameV.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
        _frameV.layer.cornerRadius = 26;
        _frameV.layer.borderWidth = 1.5;
        _frameV.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.85].CGColor;
        if (@available(iOS 13.0, *)) _frameV.layer.cornerCurve = kCACornerCurveContinuous;
        [self addSubview:_frameV];

        // Уголок для изменения размера — дуга в правом нижнем углу рамки
        _gripV = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        _gripV.userInteractionEnabled = NO;
        CAShapeLayer *arc = [CAShapeLayer layer];
        UIBezierPath *bp = [UIBezierPath bezierPathWithArcCenter:CGPointMake(8, 8) radius:22
                                                      startAngle:0 endAngle:M_PI_2 clockwise:YES];
        arc.path = bp.CGPath;
        arc.fillColor = NULL;
        arc.strokeColor = [UIColor whiteColor].CGColor;
        arc.lineWidth = 5;
        arc.lineCap = kCALineCapRound;
        [_gripV.layer addSublayer:arc];
        [self addSubview:_gripV];

        UIColor *dark = [UIColor colorWithWhite:0.12 alpha:0.62];
        UIColor *gold = [UIColor colorWithRed:0.86 green:0.69 blue:0.26 alpha:1];
        _cancel = COCPill(@"Отмена", dark, [UIColor whiteColor]);
        _done = COCPill(@"Готово", gold, [UIColor blackColor]);
        _reset = COCPill(@"Сбросить", dark, [UIColor whiteColor]);
        _ratio = COCPill(@"Пропорции: вкл", dark, [UIColor whiteColor]);
        [_cancel addTarget:self action:@selector(onCancel) forControlEvents:UIControlEventTouchUpInside];
        [_done addTarget:self action:@selector(onDone) forControlEvents:UIControlEventTouchUpInside];
        [_reset addTarget:self action:@selector(onReset) forControlEvents:UIControlEventTouchUpInside];
        [_ratio addTarget:self action:@selector(onRatio) forControlEvents:UIControlEventTouchUpInside];
        for (UIButton *b in @[ _cancel, _done, _reset, _ratio ]) [self addSubview:b];

        _title = [[UILabel alloc] init];
        _title.text = @"Экран блокировки · v0.9";
        _title.textColor = [UIColor whiteColor];
        _title.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        [_title sizeToFit];
        [self addSubview:_title];

        _hint = [[UILabel alloc] init];
        _hint.text = @"Тяни рамку — положение, уголок — размер";
        _hint.textColor = [UIColor colorWithWhite:1 alpha:0.85];
        _hint.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        _hint.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_hint];

        _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
        _pan.delegate = self;
        _pan.maximumNumberOfTouches = 1;
        [self addGestureRecognizer:_pan];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat W = self.bounds.size.width, H = self.bounds.size.height;
    CGFloat top = MAX(self.safeAreaInsets.top, 20) + 6;
    _cancel.frame = CGRectMake(16, top, _cancel.bounds.size.width, 36);
    _done.frame = CGRectMake(W - 16 - _done.bounds.size.width, top, _done.bounds.size.width, 36);
    _title.center = CGPointMake(W / 2, top + 18);

    CGFloat by = H - 190;
    CGFloat gap = 10;
    CGFloat total = _reset.bounds.size.width + gap + _ratio.bounds.size.width;
    _reset.frame = CGRectMake((W - total) / 2, by, _reset.bounds.size.width, 36);
    _ratio.frame = CGRectMake(CGRectGetMaxX(_reset.frame) + gap, by, _ratio.bounds.size.width, 36);
    _hint.frame = CGRectMake(16, by - 30, W - 32, 20);
    [self refresh];
}

// Рамку и уголок ставим по текущей раскладке часов
- (void)refresh {
    COCClockView *c = _clock;
    if (!c) return;
    [c layoutIfNeeded];
    CGRect f = CGRectInset([c editorFrame], -12, -12);
    _frameV.frame = f;
    _gripV.frame = CGRectMake(CGRectGetMaxX(f) - 36, CGRectGetMaxY(f) - 36, 40, 40);
}

- (CGPoint)gripCenter {
    return CGPointMake(CGRectGetMaxX(_frameV.frame) - 14, CGRectGetMaxY(_frameV.frame) - 14);
}

- (void)onCancel { [_clock endEditingSave:NO]; }
- (void)onDone { [_clock endEditingSave:YES]; }
- (void)onReset { [_clock editorReset]; [self refresh]; }
- (void)onRatio {
    _keepRatio = !_keepRatio;
    [_ratio setTitle:_keepRatio ? @"Пропорции: вкл" : @"Пропорции: выкл" forState:UIControlStateNormal];
    [_ratio sizeToFit];
    CGRect r = _ratio.frame; r.size.height = 36; _ratio.frame = r;
    [self setNeedsLayout];
}

#pragma mark Жесты

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)g {
    if (g != _pan) return [super gestureRecognizerShouldBegin:g];
    COCClockView *c = _clock;
    if (!c) return NO;
    CGPoint p = [_pan locationInView:self];
    CGPoint t = [_pan translationInView:self];
    CGPoint s = CGPointMake(p.x - t.x, p.y - t.y);          // где палец лёг
    CGPoint gc = [self gripCenter];
    if (hypot(s.x - gc.x, s.y - gc.y) < 44) { _mode = 2; return YES; }
    if (CGRectContainsPoint(CGRectInset([c editorDragFrame], -16, -16), s)) { _mode = 1; return YES; }
    _mode = 0;
    return NO;
}

// Пока тянем рамку, системные жесты (свайпы страниц) ждут — иначе экран уезжает из-под пальца
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)o {
    return g == _pan && o != _pan;
}

- (void)onPan:(UIPanGestureRecognizer *)g {
    COCClockView *c = _clock;
    if (!c) return;
    CGPoint t = [g translationInView:self];
    switch (g.state) {
        case UIGestureRecognizerStateBegan:
            [c editorSnapshot];
            _startCorner = CGPointMake(CGRectGetMaxX([c editorFrame]), CGRectGetMaxY([c editorFrame]));
            break;
        case UIGestureRecognizerStateChanged:
            if (_mode == 1) [c editorMoveBy:t];
            else if (_mode == 2) [c editorResizeCorner:CGPointMake(_startCorner.x + t.x, _startCorner.y + t.y)
                                            lockRatio:_keepRatio];
            [self refresh];
            break;
        default:
            _mode = 0;
            break;
    }
}

// Касания вне наших элементов тоже ловим — под редактором ничего не должно нажиматься
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *v = [super hitTest:point withEvent:event];
    return v ?: self;
}

@end

@implementation COCClockView {
    COCDigitsView *_hoursV;
    COCDigitsView *_minsV;
    UILabel *_dateL;        // дата в развёрнутом виде (1–2: три строки, 3: одна строка)
    UILabel *_weatherL;     // только в варианте 3 (справа в строке даты)
    UILabel *_dateS;        // малая дата справа (для свёрнутых часов)
    UILabel *_dbg;          // отладочная строка
    NSMutableArray<COCWidgetCard *> *_cards;
    NSTimer *_timer;
    NSDateFormatter *_fmt;
    UIColor *_tint;
    BOOL _duo, _outline;
    CGFloat _boost;

    // Кэш настроек
    BOOL _enabled, _use24, _wEn, _wAlarm, _wWeather, _wBat, _wDate, _wTxt, _showWeather;
    NSInteger _style, _colorIdx;
    CGFloat _pT, _pL, _pB, _pR;
    CGFloat _size, _w, _h, _op, _ox, _oy;
    CGFloat _wOp, _wRad, _wScale;
    NSString *_txt, *_city;
    BOOL _cEnabled, _cForce, _debug;
    CGFloat _cSpeed, _cDist;

    // Раскладки «развёрнуто» / «свёрнуто» и состояние анимации
    COCLayoutOut _E, _C;
    BOOL _hasLayout;
    CADisplayLink *_link;
    CFTimeInterval _lastTS, _activeUntil;
    CGFloat _prog, _vel, _target;
    BOOL _inter;
    NSInteger _cellCount;
    CGFloat _topSeen;
    NSString *_src;
    NSMutableArray<UIView *> *_cells;      // кэш ячеек при сканировании всего окна
    CFTimeInterval _lastScan;

    // Редактор размера и положения
    BOOL _editing;
    COCEditorView *_editor;
    UILongPressGestureRecognizer *_lp;
    CGFloat _sess[5];        // size, width, height, offsetX, offsetY на момент входа в редактор
    CGFloat _snap[5];        // то же перед текущим жестом
    CGRect _snapFrame;
}

+ (void)registerListView:(UIView *)view {
    COCListHint = view;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        _cards = [NSMutableArray array];
        _cells = [NSMutableArray array];
        _fmt = [[NSDateFormatter alloc] init];
        _fmt.locale = [NSLocale currentLocale];

        UIDevice.currentDevice.batteryMonitoringEnabled = YES;

        _hoursV = [[COCDigitsView alloc] init];
        [self addSubview:_hoursV];
        _minsV = [[COCDigitsView alloc] init];
        [self addSubview:_minsV];

        _dateL = [[UILabel alloc] init];
        _dateL.textAlignment = NSTextAlignmentLeft;
        [self addSubview:_dateL];

        _weatherL = [[UILabel alloc] init];
        _weatherL.textAlignment = NSTextAlignmentRight;
        [self addSubview:_weatherL];

        _dateS = [[UILabel alloc] init];
        _dateS.textAlignment = NSTextAlignmentRight;
        _dateS.numberOfLines = 0;
        [self addSubview:_dateS];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(weatherUpdated)
                                                     name:COCWeatherUpdated object:nil];
        [self reloadPrefs];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_timer invalidate];
    [_link invalidate];
    [_lp.view removeGestureRecognizer:_lp];
}

// Часы не перехватывают касания: свайпы, камера, фонарик работают как обычно.
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return nil;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (!self.window && _editing) [self endEditingSave:NO];
    if (self.window) [self attachLongPress];
    else if (_lp) { [_lp.view removeGestureRecognizer:_lp]; _lp = nil; }
    [_timer invalidate];
    _timer = nil;
    if (self.window) {
        if (_colorIdx == 8) {            // обои могли смениться
            [self updateColors];
            [self refreshContent];
        }
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tick)
                                                userInfo:nil repeats:YES];
        [self refreshContent];
    }
    [self syncLink];
}

- (void)updateColors {
    UIColor *h = nil, *m = nil;
    COCClockColors(_colorIdx, _duo, &h, &m);
    if (_duo) {
        // Часы ярче и плотнее минут: часы светлеют, минуты становятся чуть прозрачнее
        CGFloat b = MAX(0, MIN(100, _boost)) / 100.0;
        h = COCMixWhite(h, 0.35 * b);
        CGFloat r = 1, g = 1, bl = 1, a = 1;
        [m getRed:&r green:&g blue:&bl alpha:&a];
        m = [UIColor colorWithRed:r green:g blue:bl alpha:1.0 - 0.55 * b];
    }
    _hoursV.color = h;
    _minsV.color = m;
    _hoursV.outlineAlpha = _outline ? 0.38 : 0;
    _minsV.outlineAlpha = _outline ? 0.38 : 0;
    _tint = h;
}

- (void)tick { [self refreshContent]; }
- (void)weatherUpdated { [self refreshContent]; [self setNeedsLayout]; }

#pragma mark Настройки

- (void)reloadPrefs {
    _enabled  = COCB(@"enabled", YES);
    _style    = (NSInteger)COCF(@"layout", 1);
    _use24    = COCB(@"use24h", YES);
    _colorIdx = (NSInteger)COCF(@"clockColor", 0);
    _duo      = COCB(@"duoTone", YES);
    _boost    = COCF(@"hourBoost", 50);
    _outline  = COCB(@"digitOutline", YES);

    _pT = COCF(@"padTop", 110);
    _pL = COCF(@"padLeft", 24);
    _pB = COCF(@"padBottom", 0);
    _pR = COCF(@"padRight", 24);

    // Размер и положение задаются на экране блокировки (долгое нажатие); во время правки не трогаем
    if (!_editing) {
        _size = COCF(@"size", 100);
        _w    = COCF(@"width", 100);
        _h    = COCF(@"height", 100);
        _ox   = COCF(@"offsetX", 0);
        _oy   = COCF(@"offsetY", 0);
    }
    _op   = COCF(@"clockOpacity", 100);

    _wEn      = COCB(@"widgetsEnabled", YES);
    _wAlarm   = COCB(@"widgetAlarm", YES);
    _wWeather = COCB(@"widgetWeather", YES);
    _wBat     = COCB(@"widgetBattery", NO);
    _wDate    = COCB(@"widgetDate", NO);
    _wTxt     = COCB(@"widgetText", NO);
    _txt      = COCS(@"widgetTextValue", @"ColorOS");
    _wOp      = COCF(@"widgetOpacity", 20);
    _wRad     = COCF(@"widgetRadius", 18);
    _wScale   = COCF(@"widgetScale", 100);
    _showWeather = COCB(@"showWeather", YES);
    _city        = COCS(@"weatherCity", @"Moscow");

    // Малые часы при уведомлениях
    _cEnabled = COCB(@"collapseEnabled", YES);
    _cSpeed   = MAX(30, MIN(300, COCF(@"collapseSpeed", 100)));
    _cDist    = MAX(40, MIN(600, COCF(@"collapseDistance", 140)));
    _cForce   = COCB(@"collapseForce", NO);
    _debug    = COCB(@"debugOverlay", NO);

    if (_style < 1 || _style > 3) _style = 1;

    self.hidden = !_enabled;

    [self updateColors];

    // Перестраиваем виджеты (порядок: будильник, погода, батарея, дата, заметка)
    for (COCWidgetCard *c in _cards) [c removeFromSuperview];
    [_cards removeAllObjects];
    if (_wEn) {
        BOOL on[5] = { _wAlarm, _wWeather, _wBat, _wDate, _wTxt };
        for (NSInteger i = 0; i < 5; i++) {
            if (!on[i]) continue;
            COCWidgetCard *card = [[COCWidgetCard alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
            card.tag = i;
            card.fillAlpha = _wOp / 100.0 * 0.5;
            if (@available(iOS 13.0, *)) card.layer.cornerCurve = kCACornerCurveContinuous;
            [self addSubview:card];
            [_cards addObject:card];
        }
    }

    [self refreshContent];
    [self setNeedsLayout];
    [self syncLink];
}

#pragma mark Содержимое

- (NSAttributedString *)weatherAttrWithFont:(UIFont *)font color:(UIColor *)color {
    UIImage *img = [UIImage systemImageNamed:COCWeatherSymbol(COCWCode)];
    img = [img imageWithTintColor:color renderingMode:UIImageRenderingModeAlwaysOriginal];
    NSTextAttachment *a = [[NSTextAttachment alloc] init];
    a.image = img;
    CGFloat h = font.pointSize * 0.95;
    CGFloat w = img.size.height > 0 ? img.size.width * (h / img.size.height) : h;
    a.bounds = CGRectMake(0, -font.pointSize * 0.18, w, h);

    NSMutableAttributedString *m = [[NSMutableAttributedString alloc] initWithAttributedString:
                                    [NSAttributedString attributedStringWithAttachment:a]];
    NSString *t = [NSString stringWithFormat:@" %d°", (int)lround(COCWTemp)];
    [m appendAttributedString:[[NSAttributedString alloc] initWithString:t attributes:
        @{ NSFontAttributeName: font, NSForegroundColorAttributeName: color }]];
    return m;
}

- (void)refreshContent {
    NSDate *now = [NSDate date];

    // Ведущий ноль всегда: 0851
    _fmt.dateFormat = _use24 ? @"HH" : @"hh";
    NSString *h = [_fmt stringFromDate:now];
    _fmt.dateFormat = @"mm";
    NSString *m = [_fmt stringFromDate:now];
    _hoursV.text = h;
    _minsV.text = m;

    // Погода
    if (_showWeather || _wWeather) COCWeatherRefresh(_city);
    BOOL showW = _showWeather && COCWValid;

    // Дата / погода рядом с часами
    NSString *(^fmt)(NSString *) = ^NSString *(NSString *tpl) {
        self->_fmt.dateFormat = [NSDateFormatter dateFormatFromTemplate:tpl options:0
                                                                 locale:[NSLocale currentLocale]];
        return [self->_fmt stringFromDate:now];
    };
    NSString *dm = fmt(@"dMMM");
    NSString *wd = fmt(@"EEE");
    UIColor *col = [_tint colorWithAlphaComponent:0.92];

    if (_style == 3) {
        UIFont *f = [UIFont systemFontOfSize:18 weight:UIFontWeightRegular];
        _dateL.numberOfLines = 1;
        _dateL.attributedText = [[NSAttributedString alloc]
            initWithString:[NSString stringWithFormat:@"%@  %@", dm, wd]
                attributes:@{ NSFontAttributeName: f, NSForegroundColorAttributeName: col }];
        _weatherL.attributedText = showW ? [self weatherAttrWithFont:f color:col] : nil;
    } else {
        UIFont *f = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
        NSDictionary *attrs = @{ NSFontAttributeName: f, NSForegroundColorAttributeName: col };
        NSMutableAttributedString *ms = [[NSMutableAttributedString alloc]
            initWithString:[NSString stringWithFormat:@"%@\n%@", dm, wd] attributes:attrs];
        if (showW) {
            [ms appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:attrs]];
            [ms appendAttributedString:[self weatherAttrWithFont:f color:col]];
        }
        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
        ps.lineSpacing = 3;
        [ms addAttribute:NSParagraphStyleAttributeName value:ps range:NSMakeRange(0, ms.length)];
        _dateL.numberOfLines = 0;
        _dateL.attributedText = ms;
        _weatherL.attributedText = nil;
    }

    // Малая дата справа (как на референсе: «23 Mar / Mon / погода»), выровнена по правому краю
    {
        UIFont *f = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
        ps.alignment = NSTextAlignmentRight;
        ps.lineSpacing = 2;
        NSDictionary *attrs = @{ NSFontAttributeName: f, NSForegroundColorAttributeName: col,
                                 NSParagraphStyleAttributeName: ps };
        NSMutableAttributedString *ms = [[NSMutableAttributedString alloc]
            initWithString:[NSString stringWithFormat:@"%@\n%@", dm, wd] attributes:attrs];
        if (showW) {
            [ms appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:attrs]];
            NSMutableAttributedString *wa = [[self weatherAttrWithFont:f color:col] mutableCopy];
            [wa addAttribute:NSParagraphStyleAttributeName value:ps range:NSMakeRange(0, wa.length)];
            [ms appendAttributedString:wa];
        }
        _dateS.attributedText = ms;
    }

    // Содержимое виджетов
    for (COCWidgetCard *card in _cards) {
        switch (card.tag) {
            case COCWidgetAlarm: {
                NSDate *ad = COCNextAlarmDate();
                NSString *v = @"—";
                if (ad) {
                    _fmt.dateFormat = _use24 ? @"HH:mm" : @"h:mm";
                    v = [_fmt stringFromDate:ad];
                }
                [card setSymbol:@"alarm.fill" value:v];
                break;
            }
            case COCWidgetWeather: {
                NSString *v = COCWValid ? [NSString stringWithFormat:@"%d°", (int)lround(COCWTemp)] : @"—";
                [card setSymbol:(COCWValid ? COCWeatherSymbol(COCWCode) : @"cloud.fill") value:v];
                break;
            }
            case COCWidgetBattery: {
                UIDevice *dev = UIDevice.currentDevice;
                float lvl = dev.batteryLevel;
                NSString *v = lvl < 0 ? @"—" : [NSString stringWithFormat:@"%d%%", (int)roundf(lvl * 100)];
                BOOL chg = dev.batteryState == UIDeviceBatteryStateCharging ||
                           dev.batteryState == UIDeviceBatteryStateFull;
                [card setSymbol:(chg ? @"battery.100.bolt" : @"battery.100") value:v];
                break;
            }
            case COCWidgetDate:
                [card setSymbol:@"calendar" value:dm];
                break;
            case COCWidgetText:
                [card setSymbol:@"star.fill" value:_txt];
                break;
        }
    }

    [self setNeedsLayout];
}

#pragma mark Раскладка

// Считает обе раскладки (развёрнутую и свёрнутую) по текущим настройкам и размерам подписей.
- (void)rebuildLayout {
    CGRect R = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(_pT, _pL, _pB, _pR));
    R = CGRectOffset(R, _ox, _oy);
    CGFloat u = R.size.width;
    if (u < 10) { _hasLayout = NO; return; }

    CGFloat k = _size / 100.0;
    COCLayoutIn in;
    memset(&in, 0, sizeof(in));
    in.R = R;
    in.k = k;
    in.sx = k * _w / 100.0;
    in.sy = k * _h / 100.0;
    in.ws = _wScale / 100.0;
    in.smallK = 1.0;   // малые часы масштабируются вместе с размером, который задан в редакторе
    in.style = (int)_style;
    in.n = (int)MIN(_cards.count, (NSUInteger)COC_MAXW);

    if (_style == 3) {
        in.date = [_dateL sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
        in.weather = _weatherL.attributedText.length ? [_weatherL sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)] : CGSizeZero;
    } else {
        in.date = [_dateL sizeThatFits:CGSizeMake(MAX(u * 0.5, 80), CGFLOAT_MAX)];
    }
    in.dateS = [_dateS sizeThatFits:CGSizeMake(MAX(u * 0.5, 80), CGFLOAT_MAX)];
    COCComputeLayout(&in, &_E, &_C);
    _hasLayout = YES;
}

// Ставит все элементы в положение, соответствующее прогрессу p (0 — развёрнуто, 1 — малые часы).
- (void)applyProgress:(CGFloat)p {
    if (!_hasLayout) return;
    NSInteger n = (NSInteger)MIN(_cards.count, (NSUInteger)COC_MAXW);
    COCFrame f;
    COCInterpolate(&_E, &_C, (int)_style, (int)n, p, &f);

    CGFloat op = _op / 100.0;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    _hoursV.frame = f.hours;
    _minsV.frame = f.mins;
    _hoursV.alpha = op;
    _minsV.alpha = op;

    _dateL.frame = f.date;
    _dateL.alpha = op * f.dateA;
    _dateL.hidden = (_dateL.alpha < 0.01);
    BOOL w3 = (_style == 3) && _weatherL.attributedText.length > 0;
    _weatherL.frame = f.weather;
    _weatherL.alpha = op * f.weatherA;
    _weatherL.hidden = !w3 || (_weatherL.alpha < 0.01);
    _dateS.frame = f.dateS;
    _dateS.alpha = op * f.dateSA;
    _dateS.hidden = (_dateS.alpha < 0.01);

    CGFloat ws = _wScale / 100.0;
    for (NSInteger i = 0; i < n; i++) {
        COCWidgetCard *c = _cards[i];
        CGRect r = f.card[i];
        c.frame = r;
        CGFloat sc = _E.sq > 0 ? r.size.width / _E.sq : 1;
        c.layer.cornerRadius = MIN(_wRad * ws * sc, r.size.width / 2.0);
    }
    [CATransaction commit];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self rebuildLayout];
    [self applyProgress:_prog];
    if (_dbg) [self bringSubviewToFront:_dbg];
}

#pragma mark Редактор (долгое нажатие)

static void COCSetPref(NSString *key, double v) {
    CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFTypeRef)@(v), (__bridge CFStringRef)COC_DOMAIN);
}

// Отменяем уже начатые долгие нажатия системы (на iOS 16+ это вход в смену обоев)
static void COCCancelLongPresses(UIView *v, UIGestureRecognizer *except, int depth, int *budget) {
    if (depth > 14 || *budget <= 0) return;
    for (UIGestureRecognizer *gr in v.gestureRecognizers) {
        if (gr == except || ![gr isKindOfClass:[UILongPressGestureRecognizer class]] || !gr.enabled) continue;
        if (gr.state == UIGestureRecognizerStatePossible || gr.state == UIGestureRecognizerStateBegan ||
            gr.state == UIGestureRecognizerStateChanged) {
            gr.enabled = NO;
            gr.enabled = YES;
        }
    }
    for (UIView *s in v.subviews) {
        if (--(*budget) <= 0) return;
        COCCancelLongPresses(s, except, depth + 1, budget);
    }
}

// Долгое нажатие вешаем на окно, а не на страницу: тогда его не перехватывают другие вьюхи
// экрана блокировки. Срабатывает только в области самих часов (см. gestureRecognizerShouldBegin).
- (void)installLongPressOn:(UIView *)host {
    [self attachLongPress];
}

- (void)attachLongPress {
    UIWindow *w = self.window;
    if (!w) return;
    if (_lp && _lp.view == w) return;
    if (_lp) [_lp.view removeGestureRecognizer:_lp];
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(handleLongPress:)];
    lp.minimumPressDuration = 0.4;
    lp.allowableMovement = 14;
    lp.cancelsTouchesInView = NO;
    lp.delegate = self;
    [w addGestureRecognizer:lp];
    _lp = lp;
}

// Зона нажатия: цифры и дата в том виде, в каком они сейчас на экране (развёрнутые или малые)
- (CGRect)clockTouchZone {
    CGRect r = CGRectUnion(_hoursV.frame, _minsV.frame);
    if (!_dateL.hidden) r = CGRectUnion(r, _dateL.frame);
    if (!_dateS.hidden) r = CGRectUnion(r, _dateS.frame);
    return CGRectInset(r, -20, -20);
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)g {
    if (g != _lp) return [super gestureRecognizerShouldBegin:g];
    if (!_enabled || _editing || self.hidden || !self.window) return NO;
    return CGRectContainsPoint([self clockTouchZone], [g locationInView:self]);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)o {
    return YES;
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateBegan) return;
    int budget = 2500;
    if (self.window) COCCancelLongPresses(self.window, g, 0, &budget);
    [self beginEditing];
}

- (void)beginEditing {
    UIView *host = self.superview;
    if (!host || _editing) return;
    _editing = YES;
    _sess[0] = _size; _sess[1] = _w; _sess[2] = _h; _sess[3] = _ox; _sess[4] = _oy;

    _editor = [[COCEditorView alloc] initWithClock:self];
    _editor.frame = host.bounds;
    _editor.alpha = 0;
    [host addSubview:_editor];
    [UIView animateWithDuration:0.25 animations:^{ self->_editor.alpha = 1; }];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];

    [self setNeedsLayout];
    [self syncLink];
    [self wake];
}

- (void)endEditingSave:(BOOL)save {
    if (!_editing) return;
    if (save) {
        COCSetPref(@"size", _size);
        COCSetPref(@"width", _w);
        COCSetPref(@"height", _h);
        COCSetPref(@"offsetX", _ox);
        COCSetPref(@"offsetY", _oy);
        CFPreferencesAppSynchronize((__bridge CFStringRef)COC_DOMAIN);
    } else {
        _size = _sess[0]; _w = _sess[1]; _h = _sess[2]; _ox = _sess[3]; _oy = _sess[4];
    }
    _editing = NO;
    COCEditorView *e = _editor;
    _editor = nil;
    [UIView animateWithDuration:0.2 animations:^{ e.alpha = 0; } completion:^(BOOL f) { [e removeFromSuperview]; }];
    [self setNeedsLayout];
    [self syncLink];
    [self wake];
}

- (CGRect)editorFrame {
    [self layoutIfNeeded];
    if (!_hasLayout) return CGRectZero;
    return CGRectUnion(_E.hours, _E.mins);
}

- (CGRect)editorDragFrame {
    CGRect f = [self editorFrame];
    if (_hasLayout && _E.date.size.width > 0) f = CGRectUnion(f, _E.date);
    return f;
}

- (void)editorSnapshot {
    _snap[0] = _size; _snap[1] = _w; _snap[2] = _h; _snap[3] = _ox; _snap[4] = _oy;
    _snapFrame = [self editorFrame];
}

- (void)editorMoveBy:(CGPoint)d {
    _ox = MAX(-600, MIN(600, _snap[3] + d.x));
    _oy = MAX(-600, MIN(900, _snap[4] + d.y));
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)editorResizeCorner:(CGPoint)c lockRatio:(BOOL)lock {
    CGRect F = _snapFrame;
    if (F.size.width < 1 || F.size.height < 1) return;
    CGFloat W1 = MAX(40, MIN(self.bounds.size.width * 1.2, c.x - F.origin.x));
    CGFloat H1 = MAX(30, c.y - F.origin.y);
    CGFloat fx = W1 / F.size.width, fy = H1 / F.size.height;
    if (lock) {
        CGFloat f = (fabs(fx - 1) > fabs(fy - 1)) ? fx : fy;
        _size = MAX(30, MIN(400, _snap[0] * f));
        _w = _snap[1]; _h = _snap[2];
    } else {
        _size = _snap[0];
        _w = MAX(30, MIN(400, _snap[1] * fx));
        _h = MAX(30, MIN(400, _snap[2] * fy));
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)editorReset {
    _size = 100; _w = 100; _h = 100; _ox = 0; _oy = 0;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark Привод анимации

- (void)wake {
    _activeUntil = CACurrentMediaTime() + 0.8;
    if (_link) _link.preferredFramesPerSecond = 0;
    else [self syncLink];
}

// Включает/выключает CADisplayLink в зависимости от того, нужен ли он сейчас.
- (void)syncLink {
    BOOL need = self.window && _enabled && (_cEnabled || _cForce || _editing);
    if (need && !_link) {
        COCLinkProxy *proxy = [[COCLinkProxy alloc] initWithTarget:self];
        _link = [CADisplayLink displayLinkWithTarget:proxy selector:@selector(fire:)];
        [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        _lastTS = 0;
        _activeUntil = CACurrentMediaTime() + 1.0;
    } else if (!need && _link) {
        [_link invalidate];
        _link = nil;
        _lastTS = 0;
    }
    if (!need && _prog != 0) {
        _prog = 0; _vel = 0; _target = 0;
        [self applyProgress:0];
    }
    if (!need && _dbg) _dbg.hidden = YES;
}

// Цель сжатия по геометрии ячеек уведомлений на экране. Возвращает прогресс 0…1 и признак,
// что список сейчас ведёт палец (касание, перетаскивание или инерция прокрутки).
- (void)measureTarget:(CGFloat *)target interactive:(BOOL *)inter {
    *target = 0;
    *inter = NO;
    UIWindow *win = self.window;
    if (!win) return;
    CGFloat H = win.bounds.size.height;
    if (H < 100) H = self.bounds.size.height;

    UIView *hint = COCListHint;
    NSArray<UIView *> *cells;
    CFTimeInterval now = CACurrentMediaTime();
    if (hint && hint.window == win) {
        NSMutableArray *found = [NSMutableArray array];
        int budget = 600;
        if (COCIsNotifCell(hint)) [found addObject:hint];
        else COCCollectCells(hint, 0, &budget, self, found);
        cells = found;
        _src = @"list";
    } else {
        // Подсказки нет — сканируем всё окно, но не чаще 4 раз в секунду (в покое)
        BOOL stale = (now - _lastScan) > (now < _activeUntil ? 0.12 : 0.25);
        if (stale) {
            _lastScan = now;
            NSMutableArray *found = [NSMutableArray array];
            int budget = 2500;
            COCCollectCells(win, 0, &budget, self, found);
            _cells = found;
        }
        cells = _cells;
        _src = @"window";
    }

    CGFloat top = CGFLOAT_MAX;
    NSInteger count = 0;
    for (UIView *c in cells) {
        if (!c.window) continue;
        CGRect r; CGFloat a;
        if (!COCPresentedRect(c, win.layer, &r, &a)) continue;
        if (a < 0.05 || r.size.height < 20) continue;
        if (r.origin.y >= H - 1 || CGRectGetMaxY(r) <= 0) continue;
        count++;
        if (r.origin.y < top) top = r.origin.y;

        UIView *p = c.superview;
        while (p && ![p isKindOfClass:[UIScrollView class]]) p = p.superview;
        UIScrollView *sv = (UIScrollView *)p;
        if (sv && (sv.isTracking || sv.isDragging || sv.isDecelerating)) *inter = YES;
    }
    _cellCount = count;
    _topSeen = (count > 0) ? top : -1;
    if (count > 0) *target = COCCollapseTarget(top, H, _cDist);
}

- (void)displayTick:(CADisplayLink *)link {
    if (!self.window) { [self syncLink]; return; }
    CFTimeInterval ts = link.timestamp;
    CFTimeInterval dt = (_lastTS > 0) ? ts - _lastTS : 0;
    BOOL first = (_lastTS <= 0) || dt > 1.0;
    _lastTS = ts;
    if (dt > 0.1) dt = 0.1;

    CGFloat target = 0;
    BOOL inter = NO;
    [self measureTarget:&target interactive:&inter];
    if (_cForce) target = 1;
    if (!_cEnabled && !_cForce) target = 0;
    if (_editing) target = 0;
    _target = target;
    _inter = inter;

    CGFloat before = _prog;
    if (first || inter) {
        // Первый показ — без анимации; когда список ведёт палец — следуем точно за ним
        _prog = target;
        _vel = 0;
    } else {
        // Критически демпфированная пружина: мягкий разгон и посадка без перелёта (~0.9 с при 100%)
        CGFloat om = (10.0 / 1.5) * _cSpeed / 100.0;
        int steps = MAX(1, (int)ceil(dt * 120.0));
        CGFloat h = dt / steps;
        for (int i = 0; i < steps; i++) {
            CGFloat a = -2 * om * _vel - om * om * (_prog - target);
            _vel += a * h;
            _prog += _vel * h;
        }
        if (fabs(_prog - target) < 0.0004 && fabs(_vel) < 0.002) { _prog = target; _vel = 0; }
        _prog = COCClamp01(_prog);
    }
    if (first || fabs(_prog - before) > 1e-5) [self applyProgress:_prog];

    // В покое опрашиваем реже, при движении — на полной частоте
    CFTimeInterval now = CACurrentMediaTime();
    if (inter || fabs(_prog - _target) > 0.0004 || fabs(_vel) > 0.001) _activeUntil = now + 0.5;
    NSInteger fps = (now < _activeUntil) ? 0 : 15;
    if (link.preferredFramesPerSecond != fps) link.preferredFramesPerSecond = fps;

    [self updateDebug];
}

- (void)updateDebug {
    if (!_debug) { _dbg.hidden = YES; return; }
    if (!_dbg) {
        _dbg = [[UILabel alloc] init];
        _dbg.numberOfLines = 2;
        _dbg.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular];
        _dbg.textColor = [UIColor greenColor];
        _dbg.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
        [self addSubview:_dbg];
    }
    _dbg.hidden = NO;
    _dbg.text = [NSString stringWithFormat:@"cells %ld  top %.0f  src %@\nprog %.2f  tgt %.2f  %@",
                 (long)_cellCount, _topSeen, _src ?: @"-", _prog, _target, _inter ? @"FINGER" : @"spring"];
    _dbg.frame = CGRectMake(8, 44, MIN(self.bounds.size.width - 16, 260), 30);
    [self bringSubviewToFront:_dbg];
}

@end
