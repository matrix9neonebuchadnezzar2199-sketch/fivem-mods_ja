/**
 * ブラウザプレビュー用の最小 translations（本番は Lua / updateLocale で上書き）
 */
export const devBrowserTranslations: Record<string, string> = {
  accounts: "Accounts",
  account: " Account ",
  account_search: "Account Search...",
  account_not_found: "No accounts found",
  amount: "Amount",
  comment: "Comment",
  transfer: "Business or Citizen ID",
  cancel: "Cancel",
  confirm: "Submit",
  deposit_but: "Deposit",
  withdraw_but: "Withdraw",
  transfer_but: "Transfer",
  balance: "Available Balance",
  frozen: "Account Status: Frozen",
  cash: "Cash: $",
  transactions: "Transactions",
  _help_button_title: "Help",
  _help_button_aria: "Open help",
  fail_transfer: "Transfer failed.",
};
