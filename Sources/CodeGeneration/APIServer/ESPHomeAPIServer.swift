import Foundation
import ESPHomeSwiftCore

/// ESPHome Native API Server Code Generator
/// Generates ESP-IDF code for the ESPHome native API protocol
public struct ESPHomeAPIServer {
    
    /// Generate the complete API server implementation
    public static func generateAPIServerCode(config: APIConfig, deviceName: String, boardModel: String) -> String {
        let port = config.port ?? 6053
        let hasPassword = config.password != nil
        let hasEncryption = config.encryption != nil
        
        return """
        #include <stdio.h>
        #include <string.h>
        #include <sys/param.h>
        #include "freertos/FreeRTOS.h"
        #include "freertos/task.h"
        #include "freertos/timers.h"
        #include "esp_system.h"
        #include "esp_wifi.h"
        #include "esp_event.h"
        #include "esp_log.h"
        #include "nvs_flash.h"
        #include "esp_netif.h"
        #include "lwip/err.h"
        #include "lwip/sockets.h"
        #include "lwip/sys.h"
        #include <lwip/netdb.h>
        
        #define API_PORT \(port)
        #define API_MAX_CLIENTS 1
        #define API_BUFFER_SIZE 1024
        #define API_TASK_STACK_SIZE 4096
        #define API_TASK_PRIORITY 5
        #define CONFIG_DEVICE_NAME "\(deviceName)"
        #define CONFIG_BOARD_MODEL "\(boardModel)"
        
        static const char *TAG = "ESPHome-API";
        
        // API Message Types (subset of ESPHome protocol)
        typedef enum {
            MESSAGE_TYPE_HELLO_REQUEST = 1,
            MESSAGE_TYPE_HELLO_RESPONSE = 2,
            MESSAGE_TYPE_CONNECT_REQUEST = 3,
            MESSAGE_TYPE_CONNECT_RESPONSE = 4,
            MESSAGE_TYPE_DISCONNECT_REQUEST = 5,
            MESSAGE_TYPE_PING_REQUEST = 7,
            MESSAGE_TYPE_PING_RESPONSE = 8,
            MESSAGE_TYPE_DEVICE_INFO_REQUEST = 9,
            MESSAGE_TYPE_DEVICE_INFO_RESPONSE = 10,
            MESSAGE_TYPE_LIST_ENTITIES_REQUEST = 11,
            MESSAGE_TYPE_LIST_ENTITIES_BINARY_SENSOR_RESPONSE = 12,
            MESSAGE_TYPE_LIST_ENTITIES_SENSOR_RESPONSE = 15,
            MESSAGE_TYPE_LIST_ENTITIES_SWITCH_RESPONSE = 17,
            MESSAGE_TYPE_LIST_ENTITIES_LIGHT_RESPONSE = 19,
            MESSAGE_TYPE_LIST_ENTITIES_DONE_RESPONSE = 21,
            MESSAGE_TYPE_SUBSCRIBE_STATES_REQUEST = 20,
            MESSAGE_TYPE_BINARY_SENSOR_STATE_RESPONSE = 22,
            MESSAGE_TYPE_SENSOR_STATE_RESPONSE = 25,
            MESSAGE_TYPE_SWITCH_STATE_RESPONSE = 27,
            MESSAGE_TYPE_LIGHT_STATE_RESPONSE = 29,
            MESSAGE_TYPE_SWITCH_COMMAND_REQUEST = 33,
            MESSAGE_TYPE_LIGHT_COMMAND_REQUEST = 35
        } api_message_type_t;
        
        // API Connection State
        typedef struct {
            int socket;
            bool authenticated;
            bool subscribed_to_states;
            uint8_t rx_buffer[API_BUFFER_SIZE];
            uint8_t tx_buffer[API_BUFFER_SIZE];
        } api_client_t;
        
        static api_client_t api_client = {
            .socket = -1,
            .authenticated = false,
            .subscribed_to_states = false
        };
        
        // Component state management
        typedef struct {
            uint32_t key;
            uint8_t type; // 0=binary_sensor, 1=sensor, 2=switch, 3=light
            union {
                struct { bool value; bool has_value; } binary_sensor;
                struct { float value; bool has_value; } sensor;
                struct { bool value; } switch_state;
                struct { bool on; float brightness; float red; float green; float blue; } light;
            } state;
            bool subscribed;
        } component_state_t;
        
        #define MAX_COMPONENTS 32
        static component_state_t component_states[MAX_COMPONENTS];
        static size_t component_count = 0;
        
        // Component registration and state management functions
        static int register_component_state(uint32_t key, uint8_t type) {
            if (component_count >= MAX_COMPONENTS) return -1;
            
            component_states[component_count].key = key;
            component_states[component_count].type = type;
            component_states[component_count].subscribed = false;
            
            // Initialize state based on type
            switch (type) {
                case 0: // binary_sensor
                    component_states[component_count].state.binary_sensor.value = false;
                    component_states[component_count].state.binary_sensor.has_value = false;
                    break;
                case 1: // sensor
                    component_states[component_count].state.sensor.value = 0.0f;
                    component_states[component_count].state.sensor.has_value = false;
                    break;
                case 2: // switch
                    component_states[component_count].state.switch_state.value = false;
                    break;
                case 3: // light
                    component_states[component_count].state.light.on = false;
                    component_states[component_count].state.light.brightness = 1.0f;
                    component_states[component_count].state.light.red = 1.0f;
                    component_states[component_count].state.light.green = 1.0f;
                    component_states[component_count].state.light.blue = 1.0f;
                    break;
            }
            
            return component_count++;
        }
        
        static component_state_t* find_component_state(uint32_t key) {
            for (size_t i = 0; i < component_count; i++) {
                if (component_states[i].key == key) {
                    return &component_states[i];
                }
            }
            return NULL;
        }
        
        // Forward declarations
        static void api_send_message(uint8_t msg_type, const uint8_t *data, size_t data_len);
        static void api_handle_message(uint8_t msg_type, const uint8_t *data, size_t data_len);
        static void api_server_task(void *pvParameters);
        
        // Encode varint (Protocol Buffers encoding)
        static size_t encode_varint(uint8_t *buffer, uint32_t value) {
            size_t i = 0;
            while (value >= 0x80) {
                buffer[i++] = (value & 0x7F) | 0x80;
                value >>= 7;
            }
            buffer[i++] = value & 0x7F;
            return i;
        }
        
        // Decode varint
        static size_t decode_varint(const uint8_t *buffer, uint32_t *value) {
            *value = 0;
            size_t i = 0;
            uint32_t shift = 0;
            while (buffer[i] & 0x80) {
                *value |= ((buffer[i] & 0x7F) << shift);
                shift += 7;
                i++;
            }
            *value |= (buffer[i] << shift);
            return i + 1;
        }
        
        // Send a message with the ESPHome protocol format
        static void api_send_message(uint8_t msg_type, const uint8_t *data, size_t data_len) {
            if (api_client.socket < 0) return;
            
            size_t offset = 0;
            
            // Preamble (0x00)
            api_client.tx_buffer[offset++] = 0x00;
            
            // Message length (varint)
            offset += encode_varint(&api_client.tx_buffer[offset], data_len + 3);
            
            // Message type (varint)
            offset += encode_varint(&api_client.tx_buffer[offset], msg_type);
            
            // Copy message data
            if (data && data_len > 0) {
                memcpy(&api_client.tx_buffer[offset], data, data_len);
                offset += data_len;
            }
            
            // Send the message
            int written = send(api_client.socket, api_client.tx_buffer, offset, 0);
            if (written < 0) {
                ESP_LOGE(TAG, "Failed to send message: %d", errno);
            }
        }
        
        // Handle Hello Request
        static void handle_hello_request(const uint8_t *data, size_t len) {
            // Send Hello Response
            const char *server_info = "ESPHome Swift v0.1.0";
            api_send_message(MESSAGE_TYPE_HELLO_RESPONSE, (const uint8_t *)server_info, strlen(server_info));
        }
        
        // Handle Connect Request
        static void handle_connect_request(const uint8_t *data, size_t len) {
            \(hasPassword ? """
            // TODO: Implement password verification
            // For now, accept all connections
            """ : "// No password required")
            
            api_client.authenticated = true;
            
            // Send Connect Response (empty = success)
            api_send_message(MESSAGE_TYPE_CONNECT_RESPONSE, NULL, 0);
        }
        
        // Handle Device Info Request
        static void handle_device_info_request(const uint8_t *data, size_t len) {
            // Device info response structure (simplified)
            uint8_t response[256];
            size_t offset = 0;
            
            // Add device name
            const char *name = CONFIG_DEVICE_NAME;
            response[offset++] = 0x0A; // Field 1, string
            response[offset++] = strlen(name);
            memcpy(&response[offset], name, strlen(name));
            offset += strlen(name);
            
            // Add MAC address
            uint8_t mac[6];
            esp_wifi_get_mac(ESP_IF_WIFI_STA, mac);
            response[offset++] = 0x12; // Field 2, string
            response[offset++] = 17; // "XX:XX:XX:XX:XX:XX"
            offset += sprintf((char *)&response[offset], "%02X:%02X:%02X:%02X:%02X:%02X",
                            mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
            
            // Add ESPHome version
            response[offset++] = 0x1A; // Field 3, string
            const char *version = "2024.1.0";
            response[offset++] = strlen(version);
            memcpy(&response[offset], version, strlen(version));
            offset += strlen(version);
            
            // Add compilation time
            response[offset++] = 0x22; // Field 4, string
            const char *compile_time = __DATE__ " " __TIME__;
            response[offset++] = strlen(compile_time);
            memcpy(&response[offset], compile_time, strlen(compile_time));
            offset += strlen(compile_time);
            
            // Add model
            response[offset++] = 0x2A; // Field 5, string
            const char *model = CONFIG_BOARD_MODEL;
            response[offset++] = strlen(model);
            memcpy(&response[offset], model, strlen(model));
            offset += strlen(model);
            
            api_send_message(MESSAGE_TYPE_DEVICE_INFO_RESPONSE, response, offset);
        }
        
        // Handle List Entities Request
        static void handle_list_entities_request(const uint8_t *data, size_t len) {
            // This is where components register their entities
            // Components should implement callbacks to list their entities
            
            // For now, send empty done response
            api_send_message(MESSAGE_TYPE_LIST_ENTITIES_DONE_RESPONSE, NULL, 0);
        }
        
        // Handle Subscribe States Request  
        static void handle_subscribe_states_request(const uint8_t *data, size_t len) {
            api_client.subscribed_to_states = true;
            
            // Trigger initial state updates for all components
            components_report_initial_states();
        }
        
        // Handle incoming API messages
        static void api_handle_message(uint8_t msg_type, const uint8_t *data, size_t data_len) {
            ESP_LOGD(TAG, "Received message type: %d, length: %d", msg_type, data_len);
            
            switch (msg_type) {
                case MESSAGE_TYPE_HELLO_REQUEST:
                    handle_hello_request(data, data_len);
                    break;
                    
                case MESSAGE_TYPE_CONNECT_REQUEST:
                    handle_connect_request(data, data_len);
                    break;
                    
                case MESSAGE_TYPE_DISCONNECT_REQUEST:
                    api_client.authenticated = false;
                    api_client.subscribed_to_states = false;
                    break;
                    
                case MESSAGE_TYPE_PING_REQUEST:
                    api_send_message(MESSAGE_TYPE_PING_RESPONSE, NULL, 0);
                    break;
                    
                case MESSAGE_TYPE_DEVICE_INFO_REQUEST:
                    if (api_client.authenticated) {
                        handle_device_info_request(data, data_len);
                    }
                    break;
                    
                case MESSAGE_TYPE_LIST_ENTITIES_REQUEST:
                    if (api_client.authenticated) {
                        handle_list_entities_request(data, data_len);
                    }
                    break;
                    
                case MESSAGE_TYPE_SUBSCRIBE_STATES_REQUEST:
                    if (api_client.authenticated) {
                        handle_subscribe_states_request(data, data_len);
                    }
                    break;
                    
                default:
                    ESP_LOGW(TAG, "Unhandled message type: %d", msg_type);
                    break;
            }
        }
        
        // API client handler task
        static void api_client_task(void *pvParameters) {
            int client_sock = (int)pvParameters;
            api_client.socket = client_sock;
            
            ESP_LOGI(TAG, "Client connected");
            
            while (1) {
                // Read preamble
                uint8_t preamble;
                int len = recv(client_sock, &preamble, 1, 0);
                if (len <= 0) break;
                
                if (preamble != 0x00) {
                    ESP_LOGE(TAG, "Invalid preamble: 0x%02X", preamble);
                    break;
                }
                
                // Read message length (varint)
                uint32_t msg_length = 0;
                size_t varint_len = 0;
                for (int i = 0; i < 5; i++) {
                    uint8_t byte;
                    len = recv(client_sock, &byte, 1, 0);
                    if (len <= 0) goto disconnect;
                    
                    api_client.rx_buffer[i] = byte;
                    varint_len++;
                    
                    if (!(byte & 0x80)) break;
                }
                
                varint_len = decode_varint(api_client.rx_buffer, &msg_length);
                
                if (msg_length > API_BUFFER_SIZE - 10) {
                    ESP_LOGE(TAG, "Message too large: %d", msg_length);
                    break;
                }
                
                // Read message type and data
                len = recv(client_sock, api_client.rx_buffer, msg_length, MSG_WAITALL);
                if (len != msg_length) {
                    ESP_LOGE(TAG, "Failed to read complete message");
                    break;
                }
                
                // Decode message type
                uint32_t msg_type;
                size_t type_len = decode_varint(api_client.rx_buffer, &msg_type);
                
                // Handle the message
                api_handle_message(msg_type, &api_client.rx_buffer[type_len], msg_length - type_len);
            }
            
        disconnect:
            ESP_LOGI(TAG, "Client disconnected");
            close(client_sock);
            api_client.socket = -1;
            api_client.authenticated = false;
            api_client.subscribed_to_states = false;
            vTaskDelete(NULL);
        }
        
        // Main API server task
        static void api_server_task(void *pvParameters) {
            struct sockaddr_in server_addr;
            struct sockaddr_in client_addr;
            socklen_t client_len = sizeof(client_addr);
            
            // Create socket
            int server_sock = socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
            if (server_sock < 0) {
                ESP_LOGE(TAG, "Unable to create socket: %d", errno);
                vTaskDelete(NULL);
                return;
            }
            
            // Set socket options
            int opt = 1;
            setsockopt(server_sock, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
            
            // Bind socket
            server_addr.sin_family = AF_INET;
            server_addr.sin_addr.s_addr = htonl(INADDR_ANY);
            server_addr.sin_port = htons(API_PORT);
            
            int err = bind(server_sock, (struct sockaddr *)&server_addr, sizeof(server_addr));
            if (err != 0) {
                ESP_LOGE(TAG, "Socket bind failed: %d", errno);
                close(server_sock);
                vTaskDelete(NULL);
                return;
            }
            
            // Listen for connections
            err = listen(server_sock, 1);
            if (err != 0) {
                ESP_LOGE(TAG, "Socket listen failed: %d", errno);
                close(server_sock);
                vTaskDelete(NULL);
                return;
            }
            
            ESP_LOGI(TAG, "API server listening on port %d", API_PORT);
            
            while (1) {
                // Accept client connections
                int client_sock = accept(server_sock, (struct sockaddr *)&client_addr, &client_len);
                if (client_sock < 0) {
                    ESP_LOGE(TAG, "Unable to accept connection: %d", errno);
                    continue;
                }
                
                // Only allow one client at a time
                if (api_client.socket >= 0) {
                    ESP_LOGW(TAG, "Client already connected, rejecting new connection");
                    close(client_sock);
                    continue;
                }
                
                // Create task to handle client
                xTaskCreate(api_client_task, "api_client", API_TASK_STACK_SIZE,
                           (void *)client_sock, API_TASK_PRIORITY, NULL);
            }
            
            close(server_sock);
            vTaskDelete(NULL);
        }
        
        // Public API functions
        
        void api_setup() {
            ESP_LOGI(TAG, "Starting ESPHome API server on port %d", API_PORT);
            
            // Create API server task
            xTaskCreate(api_server_task, "api_server", API_TASK_STACK_SIZE,
                       NULL, API_TASK_PRIORITY, NULL);
        }
        
        void api_set_state_callback(state_callback_t callback) {
            state_update_callback = callback;
        }
        
        bool api_is_connected() {
            return api_client.socket >= 0 && api_client.authenticated;
        }
        
        bool api_client_subscribed() {
            return api_client.subscribed_to_states;
        }
        
        // Component state reporting functions with state persistence
        void api_send_binary_sensor_state(uint32_t key, bool state, bool missing_state) {
            // Update internal state
            component_state_t* comp_state = find_component_state(key);
            if (comp_state && comp_state->type == 0) {
                comp_state->state.binary_sensor.value = state;
                comp_state->state.binary_sensor.has_value = !missing_state;
            }
            
            if (!api_client_subscribed()) return;
            
            uint8_t data[16];
            size_t offset = 0;
            
            // Key field (field 1, fixed32)
            data[offset++] = 0x0D; // Field 1, fixed32
            memcpy(&data[offset], &key, 4);
            offset += 4;
            
            // State field (field 2, bool)
            data[offset++] = 0x10; // Field 2, varint
            data[offset++] = state ? 1 : 0;
            
            // Missing state field (field 3, bool) 
            if (missing_state) {
                data[offset++] = 0x18; // Field 3, varint
                data[offset++] = 1;
            }
            
            api_send_message(MESSAGE_TYPE_BINARY_SENSOR_STATE_RESPONSE, data, offset);
        }
        
        void api_send_sensor_state(uint32_t key, float state, bool missing_state) {
            // Update internal state
            component_state_t* comp_state = find_component_state(key);
            if (comp_state && comp_state->type == 1) {
                comp_state->state.sensor.value = state;
                comp_state->state.sensor.has_value = !missing_state;
            }
            
            if (!api_client_subscribed()) return;
            
            uint8_t data[16];
            size_t offset = 0;
            
            // Key field (field 1, fixed32)
            data[offset++] = 0x0D; // Field 1, fixed32
            memcpy(&data[offset], &key, 4);
            offset += 4;
            
            // State field (field 2, float)
            data[offset++] = 0x15; // Field 2, fixed32 (float)
            memcpy(&data[offset], &state, 4);
            offset += 4;
            
            // Missing state field (field 3, bool)
            if (missing_state) {
                data[offset++] = 0x18; // Field 3, varint
                data[offset++] = 1;
            }
            
            api_send_message(MESSAGE_TYPE_SENSOR_STATE_RESPONSE, data, offset);
        }
        
        void api_send_switch_state(uint32_t key, bool state) {
            // Update internal state
            component_state_t* comp_state = find_component_state(key);
            if (comp_state && comp_state->type == 2) {
                comp_state->state.switch_state.value = state;
            }
            
            if (!api_client_subscribed()) return;
            
            uint8_t data[8];
            size_t offset = 0;
            
            // Key field (field 1, fixed32)
            data[offset++] = 0x0D; // Field 1, fixed32
            memcpy(&data[offset], &key, 4);
            offset += 4;
            
            // State field (field 2, bool)
            data[offset++] = 0x10; // Field 2, varint
            data[offset++] = state ? 1 : 0;
            
            api_send_message(MESSAGE_TYPE_SWITCH_STATE_RESPONSE, data, offset);
        }
        
        void api_send_light_state(uint32_t key, bool state, float brightness,
                                 float red, float green, float blue) {
            // Update internal state
            component_state_t* comp_state = find_component_state(key);
            if (comp_state && comp_state->type == 3) {
                comp_state->state.light.on = state;
                if (brightness >= 0) comp_state->state.light.brightness = brightness;
                if (red >= 0) {
                    comp_state->state.light.red = red;
                    comp_state->state.light.green = green;
                    comp_state->state.light.blue = blue;
                }
            }
            
            if (!api_client_subscribed()) return;
            
            uint8_t data[32];
            size_t offset = 0;
            
            // Key field (field 1, fixed32)
            data[offset++] = 0x0D; // Field 1, fixed32
            memcpy(&data[offset], &key, 4);
            offset += 4;
            
            // State field (field 2, bool)
            data[offset++] = 0x10; // Field 2, varint
            data[offset++] = state ? 1 : 0;
            
            // Brightness field (field 3, float)
            if (brightness >= 0) {
                data[offset++] = 0x1D; // Field 3, fixed32
                memcpy(&data[offset], &brightness, 4);
                offset += 4;
            }
            
            // RGB fields (fields 4, 5, 6 - float)
            if (red >= 0) {
                data[offset++] = 0x25; // Field 4, fixed32
                memcpy(&data[offset], &red, 4);
                offset += 4;
                
                data[offset++] = 0x2D; // Field 5, fixed32
                memcpy(&data[offset], &green, 4);
                offset += 4;
                
                data[offset++] = 0x35; // Field 6, fixed32
                memcpy(&data[offset], &blue, 4);
                offset += 4;
            }
            
            api_send_message(MESSAGE_TYPE_LIGHT_STATE_RESPONSE, data, offset);
        }
        
        // Function to report all current states to newly subscribed clients
        void components_report_initial_states() {
            for (size_t i = 0; i < component_count; i++) {
                component_state_t* comp = &component_states[i];
                
                switch (comp->type) {
                    case 0: // binary_sensor
                        if (comp->state.binary_sensor.has_value) {
                            api_send_binary_sensor_state(comp->key, comp->state.binary_sensor.value, false);
                        } else {
                            api_send_binary_sensor_state(comp->key, false, true);
                        }
                        break;
                        
                    case 1: // sensor
                        if (comp->state.sensor.has_value) {
                            api_send_sensor_state(comp->key, comp->state.sensor.value, false);
                        } else {
                            api_send_sensor_state(comp->key, 0.0f, true);
                        }
                        break;
                        
                    case 2: // switch
                        api_send_switch_state(comp->key, comp->state.switch_state.value);
                        break;
                        
                    case 3: // light
                        api_send_light_state(comp->key, 
                            comp->state.light.on,
                            comp->state.light.brightness,
                            comp->state.light.red,
                            comp->state.light.green,
                            comp->state.light.blue);
                        break;
                }
            }
        }
        """
    }
    
    /// Generate component registration code for API
    public static func generateComponentAPICode() -> String {
        return """
        // Component API registration helpers
        
        typedef struct {
            uint32_t key;
            const char *name;
            const char *unique_id;
            const char *device_class;
        } api_entity_info_t;
        
        // Component registration functions with state management
        void api_register_binary_sensor(uint32_t key, const char *name,
                                       const char *unique_id, const char *device_class) {
            register_component_state(key, 0); // 0 = binary_sensor
            ESP_LOGI(TAG, "Registered binary sensor: %s (key: %d)", name, key);
        }
        
        // Sensor registration  
        void api_register_sensor(uint32_t key, const char *name,
                                const char *unique_id, const char *device_class,
                                const char *unit_of_measurement) {
            register_component_state(key, 1); // 1 = sensor
            ESP_LOGI(TAG, "Registered sensor: %s (key: %d)", name, key);
        }
        
        // Switch registration
        void api_register_switch(uint32_t key, const char *name,
                                const char *unique_id, const char *icon) {
            register_component_state(key, 2); // 2 = switch
            ESP_LOGI(TAG, "Registered switch: %s (key: %d)", name, key);
        }
        
        // Light registration
        void api_register_light(uint32_t key, const char *name,
                               const char *unique_id, bool supports_brightness,
                               bool supports_rgb) {
            register_component_state(key, 3); // 3 = light
            ESP_LOGI(TAG, "Registered light: %s (key: %d)", name, key);
        }
        """
    }
}