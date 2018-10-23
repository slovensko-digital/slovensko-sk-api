// TODO remove this after removing appropriate configuration files

package digital.slovensko.upvs.security;

import java.io.IOException;

import javax.security.auth.callback.Callback;
import javax.security.auth.callback.CallbackHandler;
import javax.security.auth.callback.UnsupportedCallbackException;

import org.apache.wss4j.common.ext.WSPasswordCallback;

public final class PasswordCallbackHandler implements CallbackHandler {
  private final String username;
  private final String password;

  public PasswordCallbackHandler(final String username, final String password) {
    this.username = username;
    this.password = password;
  }

  public void handle(final Callback[] callbacks) throws IOException, UnsupportedCallbackException {
    for (WSPasswordCallback callback: (WSPasswordCallback[]) callbacks) {
      String identifier = callback.getIdentifier();
      int usage = callback.getUsage();

      if (usage == WSPasswordCallback.DECRYPT || usage == WSPasswordCallback.SIGNATURE) {
        if (this.username.equals(identifier)) {
          callback.setPassword(this.password);
        }
      }
    }
  }
}
