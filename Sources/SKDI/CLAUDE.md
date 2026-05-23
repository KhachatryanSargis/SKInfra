# SKDI — Module Rules

Concrete `DependencyContainerProtocol` implementation. Used only at
the Composition Root — feature modules depend on the protocol in
SKCore, not on this module.

## Structure

```
SKDI/
└── FactoryDependencyContainer.swift — Thread-safe container with full
                                       scope lifecycle (unique, singleton,
                                       cached, shared, graph)
```
