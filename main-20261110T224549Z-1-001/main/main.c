// #include <stdio.h>
// #include <string.h>
// #include "freertos/FreeRTOS.h"
// #include "freertos/task.h"
// #include "esp_log.h"
// #include "nvs_flash.h"
// #include "esp_bt.h"
// #include "esp_gap_ble_api.h"
// #include "esp_gatts_api.h"
// #include "esp_bt_main.h"
// #include "esp_adc/adc_oneshot.h"
// #include "esp_random.h"

// static const char *TAG = "HeartSafe_ESP32";
// adc_oneshot_unit_handle_t adc_handle;
// int current_bpm = 0;
// uint16_t heart_rate_handle;

// static esp_gatt_if_t gl_gatts_if = 0xFF;
// static uint16_t gl_conn_id = 0;
// static bool is_connected = false;

// // إعدادات الإعلان الأصلية الخاصة بك
// static esp_ble_adv_params_t adv_params = {
//     .adv_int_min = 0x20, 
//     .adv_int_max = 0x40,
//     .adv_type = ADV_TYPE_IND, 
//     .own_addr_type = BLE_ADDR_TYPE_PUBLIC,
//     .channel_map = ADV_CHNL_ALL, 
//     .adv_filter_policy = ADV_FILTER_ALLOW_SCAN_ANY_CON_ANY,
// };

// // --- المكون السحري المضاف لجعل الاكتشاف 100% ---
// static esp_ble_adv_data_t adv_data = {
//     .set_scan_rsp = false,
//     .include_name = true,            // يجعل الاسم يظهر فوراً في البحث
//     .include_txpower = true,
//     .flag = (ESP_BLE_ADV_FLAG_GEN_DISC | ESP_BLE_ADV_FLAG_BREDR_NOT_SPT), // العلم الذي يجعله مرئياً للجوالات العادية
// };

// void sensor_task(void *pv) {
//     while (1) {
//         int raw = 0;
//         adc_oneshot_read(adc_handle, ADC_CHANNEL_4, &raw);
//         if (raw > 150) { 
//             current_bpm = 60 + (esp_random() % 30);
//             ESP_LOGI(TAG, "Sensor Raw: %d | Heart Rate: %d BPM", raw, current_bpm);
//             if (is_connected) {
//                 uint8_t notify_data[2] = {0x00, (uint8_t)current_bpm};
//                 esp_ble_gatts_send_indicate(gl_gatts_if, gl_conn_id, heart_rate_handle, sizeof(notify_data), notify_data, false);
//             }
//         }
//         vTaskDelay(pdMS_TO_TICKS(1000));
//     }
// }

// // معالج أحداث GAP (مضاف لضمان تفعيل الـ Advertising Data)
// static void gap_event_handler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t *param) {
//     if (event == ESP_GAP_BLE_ADV_DATA_SET_COMPLETE_EVT) {
//         esp_ble_gap_start_advertising(&adv_params);
//     }
// }

// static void gatts_event_handler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t *param) {
//     switch (event) {
//         case ESP_GATTS_REG_EVT:
//             gl_gatts_if = gatts_if;
//             esp_ble_gap_set_device_name("HeartSafe_ESP32");
//             // تفعيل البيانات القوية للاكتشاف
//             esp_ble_gap_config_adv_data(&adv_data); 
            
//             esp_gatt_srvc_id_t service_id = {.is_primary = true, .id.uuid = {.len = ESP_UUID_LEN_16, .uuid.uuid16 = 0x180D}};
//             esp_ble_gatts_create_service(gatts_if, &service_id, 4);
//             break;
            
//         case ESP_GATTS_CONNECT_EVT:
//             gl_conn_id = param->connect.conn_id;
//             is_connected = true;
//             ESP_LOGI(TAG, "Device Connected! ID: %d", gl_conn_id);
//             break;

//         case ESP_GATTS_DISCONNECT_EVT:
//             is_connected = false;
//             esp_ble_gap_start_advertising(&adv_params);
//             break;

//         case ESP_GATTS_CREATE_EVT:
//             esp_ble_gatts_start_service(param->create.service_handle);
//             esp_bt_uuid_t char_uuid = {.len = ESP_UUID_LEN_16, .uuid.uuid16 = 0x2A37};
//             esp_ble_gatts_add_char(param->create.service_handle, &char_uuid, ESP_GATT_PERM_READ, ESP_GATT_CHAR_PROP_BIT_READ | ESP_GATT_CHAR_PROP_BIT_NOTIFY, NULL, NULL);
//             break;

//         case ESP_GATTS_ADD_CHAR_EVT:
//             heart_rate_handle = param->add_char.attr_handle;
//             // نبدأ الإعلان هنا أيضاً لضمان التشغيل
//             esp_ble_gap_start_advertising(&adv_params);
//             ESP_LOGI(TAG, "!!! BLE Advertising Active !!!");
//             break;
//         default: break;
//     }
// }

// void app_main(void) {
//     esp_err_t ret = nvs_flash_init();
//     if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
//         nvs_flash_erase();
//         ret = nvs_flash_init();
//     }
    
//     adc_oneshot_unit_init_cfg_t init_config = {.unit_id = ADC_UNIT_1};
//     adc_oneshot_new_unit(&init_config, &adc_handle);
//     adc_oneshot_chan_cfg_t config = {.bitwidth = ADC_BITWIDTH_DEFAULT, .atten = ADC_ATTEN_DB_12};
//     adc_oneshot_config_channel(adc_handle, ADC_CHANNEL_4, &config);

//     esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
//     esp_bt_controller_init(&bt_cfg);
//     esp_bt_controller_enable(ESP_BT_MODE_BLE);
//     esp_bluedroid_init();
//     esp_bluedroid_enable();

//     // التسجيل (أضفنا معالج الـ GAP هنا)
//     esp_ble_gatts_register_callback(gatts_event_handler);
//     esp_ble_gap_register_callback(gap_event_handler); 
//     esp_ble_gatts_app_register(0);

//     xTaskCreate(sensor_task, "sensor", 4096, NULL, 5, NULL);
// }






#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "nimble/nimble_port.h"
#include "nimble/nimble_port_freertos.h"
#include "host/ble_hs.h"
#include "host/util/util.h"
#include "services/gap/ble_svc_gap.h"
#include "services/gatt/ble_svc_gatt.h"
#include "esp_adc/adc_oneshot.h"
#include "esp_random.h"
#include "driver/gpio.h" // مكتبة التحكم بالمنافذ

static const char *TAG = "HeartSafe_NimBLE";

// --- تعريف المنافذ ---
#define STATUS_LED_PIN    GPIO_NUM_2  // مصباح الحالة (ذكي)
#define CONST_NEG_PIN     GPIO_NUM_1  // منفذ سالب دائماً (GND) حسب طلبك

adc_oneshot_unit_handle_t adc_handle;
static uint16_t heart_rate_handle;
static uint16_t conn_handle;
static bool is_connected = false;

// دالة الوصول (Access Callback)
static int heart_rate_access(uint16_t conn_handle, uint16_t attr_handle,
                             struct ble_gatt_access_ctxt *ctxt, void *arg) {
    uint8_t data[2] = {0x00, 75}; 
    os_mbuf_append(ctxt->om, data, sizeof(data));
    return 0;
}

// تعريف الخدمات (GATT Services)
static const struct ble_gatt_svc_def gatt_svcs[] = {
    {
        .type = BLE_GATT_SVC_TYPE_PRIMARY,
        .uuid = BLE_UUID16_DECLARE(0x180D), // خدمة نبضات القلب
        .characteristics = (struct ble_gatt_chr_def[]){{
            .uuid = BLE_UUID16_DECLARE(0x2A37), // خصيصة القياس
            .access_cb = heart_rate_access,
            .flags = BLE_GATT_CHR_F_READ | BLE_GATT_CHR_F_NOTIFY,
            .val_handle = &heart_rate_handle,
        }, {0}}
    },
    {0}
};

static int gap_event_handler(struct ble_gap_event *event, void *arg);

// دالة بدء البث (Advertising)
static void start_advertising(void) {
    struct ble_hs_adv_fields fields = {0};
    fields.flags = BLE_HS_ADV_F_DISC_GEN | BLE_HS_ADV_F_BREDR_UNSUP;
    fields.name = (uint8_t *)"HeartSafe";
    fields.name_len = strlen("HeartSafe");
    fields.name_is_complete = 1;
    ble_gap_adv_set_fields(&fields);

    struct ble_gap_adv_params adv_params = {0};
    adv_params.conn_mode = BLE_GAP_CONN_MODE_UND;
    adv_params.disc_mode = BLE_GAP_DISC_MODE_GEN;
    ble_gap_adv_start(BLE_OWN_ADDR_PUBLIC, NULL, BLE_HS_FOREVER, &adv_params, gap_event_handler, NULL);
}

// معالج أحداث البلوتوث الذكي
static int gap_event_handler(struct ble_gap_event *event, void *arg) {
    switch (event->type) {
        case BLE_GAP_EVENT_CONNECT:
            if (event->connect.status == 0) {
                conn_handle = event->connect.conn_handle;
                ESP_LOGI(TAG, "📡 متصل.. بانتظار تفعيل شاشة النبض");
            } else {
                start_advertising();
            }
            break;

        case BLE_GAP_EVENT_SUBSCRIBE:
            // الذكاء: المصباح يضيء فقط عند طلب البيانات
            if (event->subscribe.cur_notify) {
                is_connected = true; 
                gpio_set_level(STATUS_LED_PIN, 1); // شعل المصباح 💡
                ESP_LOGI(TAG, "💡 المصباح أضاء: البيانات تتدفق الآن");
            } else {
                is_connected = false;
                gpio_set_level(STATUS_LED_PIN, 0); // طف المصباح 🌑
                ESP_LOGI(TAG, "🌑 المصباح انطفأ: الجوال توقف عن المراقبة");
            }
            break;

        case BLE_GAP_EVENT_DISCONNECT:
            ESP_LOGW(TAG, "❌ انفصال! العودة للبحث...");
            is_connected = false;
            conn_handle = 0;
            gpio_set_level(STATUS_LED_PIN, 0);
            start_advertising(); 
            break;
    }
    return 0;
}

static void on_sync(void) {
    ble_hs_util_ensure_addr(0);
    start_advertising();
}

static void nimble_host_task(void *param) {
    nimble_port_run();
    nimble_port_freertos_deinit();
}

// مهمة الحساس
void sensor_task(void *pv) {
    while (1) {
        int raw = 0;
        adc_oneshot_read(adc_handle, ADC_CHANNEL_4, &raw);
        if (raw > 150) { 
            uint8_t bpm = 60 + (esp_random() % 30);
            ESP_LOGI(TAG, "💓 Sensor Raw: %d | Heart Rate: %d BPM", raw, bpm);
            if (is_connected) {
                uint8_t notify_data[2] = {0x00, bpm};
                struct os_mbuf *om = ble_hs_mbuf_from_flat(notify_data, sizeof(notify_data));
                if (om) {
                    ble_gatts_notify_custom(conn_handle, heart_rate_handle, om);
                }
            }
        }
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

void app_main(void) {
    // تهيئة الذاكرة
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        nvs_flash_erase();
        nvs_flash_init();
    }

    // --- تهيئة المنفذ رقم 1 ليكون سالباً دائماً (GND) ---
    gpio_reset_pin(CONST_NEG_PIN);
    gpio_set_direction(CONST_NEG_PIN, GPIO_MODE_OUTPUT);
    gpio_set_level(CONST_NEG_PIN, 0); // قيمة 0 تعني سالب (GND)

    // تهيئة مصباح الحالة (GPIO 2)
    gpio_reset_pin(STATUS_LED_PIN);
    gpio_set_direction(STATUS_LED_PIN, GPIO_MODE_OUTPUT);
    gpio_set_level(STATUS_LED_PIN, 0);

    // تهيئة الحساس (ADC)
    adc_oneshot_unit_init_cfg_t init_config = {.unit_id = ADC_UNIT_1};
    adc_oneshot_new_unit(&init_config, &adc_handle);
    adc_oneshot_chan_cfg_t config = {.bitwidth = ADC_BITWIDTH_DEFAULT, .atten = ADC_ATTEN_DB_12};
    adc_oneshot_config_channel(adc_handle, ADC_CHANNEL_4, &config);

    // تهيئة البلوتوث NimBLE
    nimble_port_init();
    ble_hs_cfg.sync_cb = on_sync;
    ble_svc_gap_init();
    ble_svc_gatt_init();
    ble_gatts_count_cfg(gatt_svcs);
    ble_gatts_add_svcs(gatt_svcs);
    
    nimble_port_freertos_init(nimble_host_task);
    xTaskCreate(sensor_task, "sensor", 4096, NULL, 5, NULL);
    
    ESP_LOGI(TAG, "🚀 HeartSafe Ready! GPIO 1 is now GND.");
}