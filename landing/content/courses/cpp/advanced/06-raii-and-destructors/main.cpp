#include <iostream>
#include <stdexcept>
#include <string>

// RAII: the constructor acquires a resource and the destructor releases it.
class DbConnection {
    std::string name_;
public:
    explicit DbConnection(std::string name) : name_(name) { std::cout << "open  " << name_ << "\n"; }
    ~DbConnection() { std::cout << "close " << name_ << "\n"; }    // destructor
};

// A transaction rolls back by itself unless commit() was called.
class Transaction {
    bool committed_ = false;
public:
    Transaction() { std::cout << "  begin\n"; }
    void commit() { committed_ = true; std::cout << "  commit\n"; }
    ~Transaction() { if (!committed_) std::cout << "  rollback\n"; }
};

void transfer(int amount) {
    DbConnection db("bank.db");
    Transaction tx;
    if (amount > 500) throw std::runtime_error("limit exceeded");
    tx.commit();
}   // leaving the scope: tx is destroyed first, then db (reverse order)

int main() {
    transfer(200);
    try { transfer(900); }    // the exception leaves transfer(), but the destructors run
    catch (const std::exception& e) { std::cout << "Error: " << e.what() << "\n"; }
}
