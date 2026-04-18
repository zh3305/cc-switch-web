#[test]
fn headless_runtime_installs_rustls_crypto_provider() {
    assert!(
        !cc_switch_core::is_rustls_crypto_provider_initialized(),
        "测试进程启动前不应已有默认 Rustls provider"
    );

    cc_switch_core::ensure_rustls_crypto_provider()
        .expect("headless runtime should install a default Rustls crypto provider");

    assert!(
        cc_switch_core::is_rustls_crypto_provider_initialized(),
        "初始化后应能读取到默认 Rustls provider"
    );
}
