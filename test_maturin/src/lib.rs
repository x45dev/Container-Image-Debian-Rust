// ./maturin_test/src/lib.rs
use pyo3::prelude::*;

#[pyfunction]
fn say_hello() -> PyResult<String> {
    Ok("Hello from Rust!".to_string())
}

#[pymodule]
fn maturin_test_package(_py: Python, m: &PyModule) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(say_hello, m)?)?;
    Ok(())
}