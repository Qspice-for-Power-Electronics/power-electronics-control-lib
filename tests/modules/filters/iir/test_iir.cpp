#include "../../../src/modules/filters/iir/iir.h"
#include <assert.h>
#include <math.h>

void test_iir_init() {
    IirModule filter;
    IirParams params = {1e-4f, 100.0f, 0, 0.0f};
    
    int result = iir_module_init(&filter, &params);
    assert(result == 0);
}

void test_iir_step() {
    IirModule filter;
    IirParams params = {1e-4f, 100.0f, 0, 0.0f};
    iir_module_init(&filter, &params);

    // Test DC response
    filter.in.u = 1.0f;
    for(int i = 0; i < 1000; i++) {
        iir_module_step(&filter);
    }
    assert(fabs(filter.out.y - 1.0f) < 0.01f);
}

int main() {
    test_iir_init();
    test_iir_step();
    return 0;
}
