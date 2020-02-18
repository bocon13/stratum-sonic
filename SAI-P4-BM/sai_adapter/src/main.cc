extern "C" {
#include <sai.h>
}
#include <cstddef>


#define UNREFERENCED_PARAMETER(P)   (P)


const char* test_profile_get_value(
    _In_ sai_switch_profile_id_t profile_id,
    _In_ const char* variable)
{
    UNREFERENCED_PARAMETER(profile_id);
    UNREFERENCED_PARAMETER(variable);

    return NULL;
}

int test_profile_get_next_value(
    _In_ sai_switch_profile_id_t profile_id,
    _Out_ const char** variable,
    _Out_ const char** value)
{
    UNREFERENCED_PARAMETER(profile_id);
    UNREFERENCED_PARAMETER(variable);
    UNREFERENCED_PARAMETER(value);

    return -1;
}

const sai_service_method_table_t test_services =
{
    test_profile_get_value,
    test_profile_get_next_value
};

int main() {
    sai_api_initialize(0, (sai_service_method_table_t *)&test_services);
    return 0;
}
